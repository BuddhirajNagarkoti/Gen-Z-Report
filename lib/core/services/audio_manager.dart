import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'sync_data_service.dart';
import 'audio_download_service.dart';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final AudioDownloadService _downloadService = GetIt.I<AudioDownloadService>();
  
  int _currentPage = 1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  String _statusMessage = '';
  double _downloadProgress = 0;
  bool _isPrefetching = false;
  double _playbackSpeed = 1.0;
  
  bool _hasFetchedAudioList = false;
  Set<int> _availableAudioPages = {};
  
  AudioManager() {
    _init();
  }

  Future<void> _fetchAvailableAudioList() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('voices');
      final listResult = await storageRef.listAll();
      final Set<int> available = {};
      for (var item in listResult.items) {
        final name = item.name;
        if (name.startsWith('pg_') && name.endsWith('.mp3')) {
          final numStr = name.substring(3, name.length - 4);
          final num = int.tryParse(numStr);
          if (num != null) {
            available.add(num);
          }
        }
      }
      _availableAudioPages = available;
      _hasFetchedAudioList = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AudioManager: Failed to fetch audio list: $e');
    }
  }

  void _init() {
    _fetchAvailableAudioList();
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

  void _playNextPage() async {
    int nextPg = _currentPage;
    if (_currentPage < 35) {
      nextPg = _currentPage + 1;
    } else if (_currentPage == 35) {
      nextPg = 648;
    } else if (_currentPage >= 648 && _currentPage < 711) {
      nextPg = _currentPage + 1;
    } else {
      // END OF PLAYLIST
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
      return;
    }
    await playPage(nextPg);
  }

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  double get downloadProgress => _downloadProgress;
  bool get isPrefetching => _isPrefetching;
  bool get isActive => _isPlaying || _position > Duration.zero;
  double get playbackSpeed => _playbackSpeed;

  bool isAudioAvailable(int pageNum) {
    if (_hasFetchedAudioList) {
      return _availableAudioPages.contains(pageNum);
    }
    // Fallback to hardcoded list while loading from network
    if (pageNum >= 1 && pageNum <= 36) return true;
    if (pageNum >= 648 && pageNum <= 711) return true;
    return false;
  }

  void setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setPlaybackRate(speed);
    notifyListeners();
  }

  Future<void> deletePageAudio(int pageNum) async {
    await _downloadService.deletePage(pageNum);
    notifyListeners(); // Refresh UI if needed
  }

  Future<bool> checkIsDownloaded(int pageNum) {
    return _downloadService.isDownloaded(pageNum);
  }

  Future<void> playPage(int pageNum) async {
    if (_currentPage == pageNum && _isPlaying) return;
    
    _currentPage = pageNum;
    
    if (!isAudioAvailable(pageNum)) {
      await stop();
      _statusMessage = 'यो पृष्ठको लागि अडियो उपलब्ध छैन';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _position = Duration.zero;
    _duration = Duration.zero;
    _statusMessage = 'पृष्ठ $pageNum लोड हुँदैछ...';
    notifyListeners();

    try {
      _statusMessage = 'अडियो प्लेयर रोक्दैछ...';
      notifyListeners();
      await _player.stop();

      // On Web, we stream directly from URL because path_provider/local files aren't supported
      if (kIsWeb) {
        _statusMessage = 'क्लाउडबाट फेच गर्दैछ (Web)...';
        notifyListeners();
        final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
        final storageRef = FirebaseStorage.instance.ref().child('voices/$fileName');
        final url = await storageRef.getDownloadURL();
        await _player.setSource(UrlSource(url));
        debugPrint('AudioManager: Streaming from Firebase for Page $pageNum (Web)');
      } else {
        // Mobile/Desktop: Try local cache first
        _statusMessage = 'स्थानीय फाइल चेक गर्दैछ...';
        notifyListeners();
        final isDownloaded = await _downloadService.isDownloaded(pageNum);
        if (isDownloaded) {
          _statusMessage = 'स्थानीय फाइलबाट बजाउँदै...';
          notifyListeners();
          final localPath = await _downloadService.getLocalPath(pageNum);
          await _player.setSource(DeviceFileSource(localPath));
          debugPrint('AudioManager: Playing local file for Page $pageNum');
        } else {
          _statusMessage = 'क्लाउडबाट फेच गर्दैछ...';
          notifyListeners();
          final fileName = 'pg_${pageNum.toString().padLeft(3, '0')}.mp3';
          final storageRef = FirebaseStorage.instance.ref().child('voices/$fileName');
          final url = await storageRef.getDownloadURL();
          _statusMessage = 'फेच गरियो, बफर गर्दैछ...';
          notifyListeners();
          await _player.setSource(UrlSource(url));
          debugPrint('AudioManager: Streaming from Firebase for Page $pageNum');
        }
      }

      _statusMessage = 'सुरु गर्दैछ...';
      notifyListeners();
      await _player.setPlaybackRate(_playbackSpeed);
      await _player.resume();
      _isPlaying = true;
      _isLoading = false;
      _statusMessage = '';
    } catch (e) {
      debugPrint('AudioManager: FAILED to play audio for Page $pageNum - $e');
      _isPlaying = false;
      _isLoading = false;
      _statusMessage = 'अडियो लोड गर्न असफल भयो';
    } finally {
      // Small safety check
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
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void _prefetchNextPage() async {
    if (_isPrefetching || _currentPage >= 898 || kIsWeb) return;
    
    final nextPageNum = _currentPage + 1;
    final isDownloaded = await _downloadService.isDownloaded(nextPageNum);
    if (!isDownloaded) {
      _isPrefetching = true;
      try {
        debugPrint('AudioManager: Pre-fetching Page $nextPageNum');
        await _downloadService.downloadPage(nextPageNum);
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

