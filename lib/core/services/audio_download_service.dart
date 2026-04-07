import 'audio_download_service_interface.dart';
import 'audio_download_service_stub.dart'
    if (dart.library.io) 'audio_download_service_mobile.dart'
    if (dart.library.html) 'audio_download_service_web.dart' as impl;

export 'audio_download_service_interface.dart';

AudioDownloadService getAudioService() => impl.createAudioDownloadService();
