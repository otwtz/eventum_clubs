import 'package:flutter_map/flutter_map.dart';

import 'app_map_tile_provider_stub.dart'
    if (dart.library.io) 'app_map_tile_provider_io.dart' as impl;

/// Предзагрузка каталога кэша (await из [setupServiceLocator] перед runApp).
Future<void> warmupMapTilesCacheDirectory() =>
    impl.warmupMapTilesCacheDirectoryImpl();

/// Один общий [TileProvider] на приложение: дисковый кэш тайлов (не web).
TileProvider resolveAppMapTileProvider() => impl.resolveAppMapTileProviderImpl();
