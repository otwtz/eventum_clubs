import 'package:flutter_map/flutter_map.dart';

Future<void> warmupMapTilesCacheDirectoryImpl() async {}

TileProvider resolveAppMapTileProviderImpl() =>
    NetworkTileProvider(silenceExceptions: true);
