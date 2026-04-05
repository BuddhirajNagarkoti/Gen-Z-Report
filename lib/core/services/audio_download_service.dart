import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AudioDownloadService {
  static const String audioSubDir = 'audio_cache';

  /// Returns the local path for a given page's audio file.
  Future<String> getLocalPath(int pageNum) async {
    if (kIsWeb) return ''; // local files not supported on web
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/$audioSubDir');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
    return '${audioDir.path}/$fileName';
  }

  /// Checks if the audio file for a given page exists locally.
  Future<bool> isDownloaded(int pageNum) async {
    if (kIsWeb) return false;
    final path = await getLocalPath(pageNum);
    return File(path).exists();
  }

  /// Downloads the audio file for a given page from Firebase Storage.
  Future<String?> downloadPage(int pageNum, {Function(double)? onProgress}) async {
    if (kIsWeb) return null;
    try {
      final localPath = await getLocalPath(pageNum);
      final file = File(localPath);

      // Map the page number to the storage path
      final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
      final storageRef = FirebaseStorage.instance.ref().child('voices/$fileName');
      
      final downloadTask = storageRef.writeToFile(file);

      downloadTask.snapshotEvents.listen((taskSnapshot) {
        if (onProgress != null) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress(progress);
        }
      });

      await downloadTask;
      debugPrint('AudioDownloadService: Successfully downloaded Page $pageNum to $localPath');
      return localPath;
    } catch (e) {
      debugPrint('AudioDownloadService: ERROR downloading Page $pageNum: $e');
      return null;
    }
  }

  /// Deletes a cached audio file.
  Future<void> deletePage(int pageNum) async {
    if (kIsWeb) return;
    final path = await getLocalPath(pageNum);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clears all cached audio files.
  Future<void> clearCache() async {
    if (kIsWeb) return;
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/$audioSubDir');
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
  }
}
