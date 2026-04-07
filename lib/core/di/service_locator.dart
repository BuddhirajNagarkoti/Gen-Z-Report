import 'package:get_it/get_it.dart';
import '../services/sync_data_service.dart';
import '../services/audio_manager.dart';
import '../services/audio_download_service.dart';
import '../../data/repositories/page_repository.dart';
import '../services/language_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/bookmark_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection(SharedPreferences prefs) async {
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<BookmarkService>(() => BookmarkService(prefs));
  getIt.registerLazySingleton<LanguageService>(() => LanguageService());
  getIt.registerLazySingleton<SyncDataService>(() => SyncDataService());
  getIt.registerLazySingleton<AudioDownloadService>(() => getAudioService());
  
  final pageRepo = PageRepository();
  getIt.registerLazySingleton<PageRepository>(() => pageRepo);
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());
}

