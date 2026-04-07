import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'audio_download_service_interface.dart';

class MobileAudioDownloadService implements AudioDownloadService {
  static const String audioSubDir = 'audio_cache';

  @override
  Future<String> getLocalPath(int pageNum) async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = io.Directory('${directory.path}/$audioSubDir');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
    return '${audioDir.path}/$fileName';
  }

  @override
  Future<bool> isDownloaded(int pageNum) async {
    final path = await getLocalPath(pageNum);
    return io.File(path).exists();
  }

  @override
  Future<String?> downloadPage(int pageNum, {Function(double)? onProgress}) async {
    try {
      final localPath = await getLocalPath(pageNum);
      final file = io.File(localPath);

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

  @override
  Future<void> deletePage(int pageNum) async {
    final path = await getLocalPath(pageNum);
    final file = io.File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clearCache() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = io.Directory('${directory.path}/$audioSubDir');
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
  }
}

AudioDownloadService createAudioDownloadService() => MobileAudioDownloadService();
