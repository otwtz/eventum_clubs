import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../map/app_map_tile_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  await warmupMapTilesCacheDirectory();
}
