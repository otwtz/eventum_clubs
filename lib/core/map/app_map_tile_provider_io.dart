import 'dart:async';
import 'dart:collection';
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:path_provider/path_provider.dart';

/// Общий HTTP-клиент (keep-alive между тайлами, один на процесс).
final BaseClient _mapTileSharedHttpClient = RetryClient(Client());

Directory? _mapTileCacheRoot;

DiskCachedCartoTileProvider? _cachedTileProviderSingleton;

Future<void> warmupMapTilesCacheDirectoryImpl() async {
  if (_mapTileCacheRoot != null) return;
  try {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/map_carto_tiles_v1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _mapTileCacheRoot = dir;
  } catch (_) {
    _mapTileCacheRoot = null;
  }
}

TileProvider resolveAppMapTileProviderImpl() {
  if (_mapTileCacheRoot == null) {
    return NetworkTileProvider(silenceExceptions: true);
  }
  _cachedTileProviderSingleton ??=
      DiskCachedCartoTileProvider(cacheDirectory: _mapTileCacheRoot!);
  return _cachedTileProviderSingleton!;
}

/// Сеть + чтение/запись PNG тайлов в кэше приложения.
class DiskCachedCartoTileProvider extends TileProvider {
  DiskCachedCartoTileProvider({
    required Directory cacheDirectory,
    super.headers,
    BaseClient? httpClient,
    this.silenceExceptions = false,
  })  : _cacheDirectory = cacheDirectory,
        _httpClient = httpClient ?? _mapTileSharedHttpClient;

  final Directory _cacheDirectory;
  final BaseClient _httpClient;
  final bool silenceExceptions;

  final HashMap<TileCoordinates, Completer<void>> _tilesInProgress =
      HashMap<TileCoordinates, Completer<void>>();

  File _cacheFileForUrl(String tileUrl) {
    final hex = sha256.convert(utf8.encode(tileUrl)).toString();
    return File('${_cacheDirectory.path}/$hex.png');
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final primaryUrl = getTileUrl(coordinates, options);
    final fallbackResolved = getTileFallbackUrl(coordinates, options);

    return _DiskCachedMapImageProvider(
      url: primaryUrl,
      resolvedFallbackUrl: fallbackResolved,
      headers: headers,
      httpClient: _httpClient,
      silenceExceptions: silenceExceptions,
      readCacheFile: () async {
        try {
          final f = _cacheFileForUrl(primaryUrl);
          if (await f.exists()) return await f.readAsBytes();
        } catch (_) {}
        return null;
      },
      writeCacheBytes: (String tileUrl, Uint8List bytes) async {
        try {
          final f = _cacheFileForUrl(tileUrl);
          await f.writeAsBytes(bytes, flush: true);
        } catch (_) {}
      },
      readFallbackCache: fallbackResolved == null
          ? null
          : () async {
              try {
                final f = _cacheFileForUrl(fallbackResolved);
                if (await f.exists()) return await f.readAsBytes();
              } catch (_) {}
              return null;
            },
      startedLoading: () {
        _tilesInProgress[coordinates] = Completer<void>();
      },
      finishedLoadingBytes: () {
        _tilesInProgress[coordinates]?.complete();
        _tilesInProgress.remove(coordinates);
      },
    );
  }

  @override
  Future<void> dispose() async {
    if (_tilesInProgress.isNotEmpty) {
      await Future.wait(_tilesInProgress.values.map((c) => c.future));
    }
    // Не закрываем общий [_mapTileSharedHttpClient].
    super.dispose();
  }
}

@immutable
class _DiskCachedMapImageProvider
    extends ImageProvider<_DiskCachedMapImageProvider> {
  // ignore: prefer_const_constructors_in_immutables — колбэки с замыканиями на координаты тайла.
  _DiskCachedMapImageProvider({
    required this.url,
    required this.resolvedFallbackUrl,
    required this.headers,
    required this.httpClient,
    required this.silenceExceptions,
    required this.readCacheFile,
    required this.writeCacheBytes,
    required this.readFallbackCache,
    required this.startedLoading,
    required this.finishedLoadingBytes,
  });

  final String url;

  /// Уже развёрнутый URL одного запасного тайла (или null).
  final String? resolvedFallbackUrl;
  final Map<String, String> headers;
  final BaseClient httpClient;
  final bool silenceExceptions;

  final Future<Uint8List?> Function() readCacheFile;
  final Future<void> Function(String url, Uint8List bytes) writeCacheBytes;
  final Future<Uint8List?> Function()? readFallbackCache;

  final void Function() startedLoading;
  final void Function() finishedLoadingBytes;

  @override
  ImageStreamCompleter loadImage(
    _DiskCachedMapImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _loadCycle(key, decode),
        scale: 1,
        debugLabel: url,
        informationCollector: () => [
          DiagnosticsProperty('URL', url),
          DiagnosticsProperty('Fallback', resolvedFallbackUrl),
        ],
      );

  Future<Codec> _loadCycle(
    _DiskCachedMapImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    Future<Codec> decodeBytes(Uint8List bytes) =>
        ImmutableBuffer.fromUint8List(bytes).then(decode);

    final fromDiskPrimary = await readCacheFile();
    if (fromDiskPrimary != null && fromDiskPrimary.isNotEmpty) {
      try {
        return await decodeBytes(fromDiskPrimary);
      } catch (_) {}
    }

    if (readFallbackCache != null) {
      final fromFb = await readFallbackCache!();
      if (fromFb != null && fromFb.isNotEmpty) {
        try {
          return await decodeBytes(fromFb);
        } catch (_) {}
      }
    }

    startedLoading();
    try {
      final bytes =
          await httpClient.readBytes(Uri.parse(url), headers: headers);
      finishedLoadingBytes();
      unawaited(writeCacheBytes(url, bytes));
      return await decodeBytes(bytes);
    } catch (primaryErr, primaryStack) {
      finishedLoadingBytes();
      if (resolvedFallbackUrl != null) {
        scheduleMicrotask(
          () => PaintingBinding.instance.imageCache.evict(key),
        );
        startedLoading();
        try {
          final fb = await httpClient.readBytes(
            Uri.parse(resolvedFallbackUrl!),
            headers: headers,
          );
          finishedLoadingBytes();
          unawaited(writeCacheBytes(resolvedFallbackUrl!, fb));
          return await decodeBytes(fb);
        } catch (_) {
          finishedLoadingBytes();
          scheduleMicrotask(
            () => PaintingBinding.instance.imageCache.evict(key),
          );
          if (silenceExceptions) {
            return await decodeBytes(TileProvider.transparentImage);
          }
          Error.throwWithStackTrace(primaryErr, primaryStack);
        }
      }
      scheduleMicrotask(
        () => PaintingBinding.instance.imageCache.evict(key),
      );
      if (silenceExceptions) {
        return await decodeBytes(TileProvider.transparentImage);
      }
      Error.throwWithStackTrace(primaryErr, primaryStack);
    }
  }

  @override
  SynchronousFuture<_DiskCachedMapImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  /// Только основной URL — совпадает с поведением [MapNetworkImageProvider] без вторичного ключей для кеша Flutter.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _DiskCachedMapImageProvider && url == other.url);

  @override
  int get hashCode => url.hashCode;
}
