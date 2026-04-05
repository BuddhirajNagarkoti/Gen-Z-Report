import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'sync_data_service.dart';
import 'audio_download_service.dart';
import 'dart:io';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final AudioDownloadService _downloadService = GetIt.I<AudioDownloadService>();
  
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentPage = 1;
  bool _isLoading = false;
  double _downloadProgress = 0;
  bool _isPrefetching = false;

  AudioManager() {
    _init();
  }

  void _init() {
    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();

      // Background pre-fetching of next page audio
      if (_duration > Duration.zero && p.inSeconds > _duration.inSeconds * 0.8) {
        _prefetchNextPage();
      }
    });

    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      if (_isPlaying || state == PlayerState.paused || state == PlayerState.stopped) {
        _isLoading = false;
      }
      notifyListeners();
    });
    
    _player.onLog.listen((log) {
      debugPrint('AudioPlayer Log: $log');
    });

    _player.onPlayerComplete.listen((event) {
      _playNextPage();
    });
  }

  void _playNextPage() {
    // Arbitrary limit 898 (approx total pages in report)
    if (_currentPage < 898) {
      playPage(_currentPage + 1);
    } else {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    }
  }

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  double get downloadProgress => _downloadProgress;
  bool get isActive => _isPlaying || _position > Duration.zero;

  Future<void> playPage(int pageNum) async {
    if (_currentPage == pageNum && _isPlaying) return;
    
    _currentPage = pageNum;
    _isLoading = true;
    notifyListeners();

    try {
      await _player.stop();

      // On Web, we stream directly from URL because path_provider/local files aren't supported
      if (kIsWeb) {
        final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
        final storageRef = FirebaseStorage.instance.ref().child('voices/$fileName');
        final url = await storageRef.getDownloadURL();
        await _player.setSource(UrlSource(url));
        debugPrint('AudioManager: Streaming from Firebase for Page $pageNum (Web)');
      } else {
        // Mobile/Desktop: Try local cache first
        final isDownloaded = await _downloadService.isDownloaded(pageNum);
        if (isDownloaded) {
          final localPath = await _downloadService.getLocalPath(pageNum);
          await _player.setSource(DeviceFileSource(localPath));
          debugPrint('AudioManager: Playing local file for Page $pageNum');
        } else {
          final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
          final storageRef = FirebaseStorage.instance.ref().child('voices/$fileName');
          final url = await storageRef.getDownloadURL();
          await _player.setSource(UrlSource(url));
          debugPrint('AudioManager: Streaming from Firebase for Page $pageNum');
        }
      }

      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('AudioManager: FAILED to play audio for Page $pageNum - $e');
      _isPlaying = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Downloads the current page's audio for offline use.
  Future<void> downloadCurrentPage() async {
    final pageNum = _currentPage;
    if (await _downloadService.isDownloaded(pageNum)) return;

    _isLoading = true;
    _downloadProgress = 0;
    notifyListeners();

    await _downloadService.downloadPage(
      pageNum,
      onProgress: (p) {
        _downloadProgress = p;
        notifyListeners();
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void _prefetchNextPage() async {
    if (_isPrefetching || _currentPage >= 898 || kIsWeb) return;
    
    final nextLocalPath = await _downloadService.getLocalPath(_currentPage + 1);
    final file = File(nextLocalPath);
    if (!await file.exists()) {
      _isPrefetching = true;
      try {
        debugPrint('AudioManager: Pre-fetching Page ${_currentPage + 1}');
        await _downloadService.downloadPage(_currentPage + 1);
      } catch (e) {
        debugPrint('AudioManager: Pre-fetch failed: $e');
      } finally {
        Future.delayed(const Duration(seconds: 10), () => _isPrefetching = false);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

