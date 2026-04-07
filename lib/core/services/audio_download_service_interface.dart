abstract class AudioDownloadService {
  
  Future<String> getLocalPath(int pageNum);
  Future<bool> isDownloaded(int pageNum);
  Future<String?> downloadPage(int pageNum, {Function(double)? onProgress});
  Future<void> deletePage(int pageNum);
  Future<void> clearCache();
}
