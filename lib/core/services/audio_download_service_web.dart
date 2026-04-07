import 'audio_download_service_interface.dart';

class WebAudioDownloadService implements AudioDownloadService {
  @override
  Future<String> getLocalPath(int pageNum) async => '';

  @override
  Future<bool> isDownloaded(int pageNum) async => false;

  @override
  Future<String?> downloadPage(int pageNum, {Function(double)? onProgress}) async => null;

  @override
  Future<void> deletePage(int pageNum) async {}

  @override
  Future<void> clearCache() async {}
}

AudioDownloadService createAudioDownloadService() => WebAudioDownloadService();
