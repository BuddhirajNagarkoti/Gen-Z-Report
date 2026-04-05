import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkService {
  static const String _keyAudioProgress = 'audio_progress_';
  static const String _keyTextBookmarks = 'text_bookmarks';
  static const String _keyAudioBookmarks = 'audio_bookmarks';

  final SharedPreferences _prefs;

  BookmarkService(this._prefs);

  // --- Audio Progress (Resume) ---
  
  Future<void> saveAudioProgress(String chapterId, int positionMs) async {
    await _prefs.setInt('$_keyAudioProgress$chapterId', positionMs);
  }

  int getAudioProgress(String chapterId) {
    return _prefs.getInt('$_keyAudioProgress$chapterId') ?? 0;
  }

  // --- Text Bookmarks ---

  Future<void> addTextBookmark(int page) async {
    final List<String> current = _prefs.getStringList(_keyTextBookmarks) ?? [];
    if (!current.contains(page.toString())) {
      current.add(page.toString());
      await _prefs.setStringList(_keyTextBookmarks, current);
    }
  }

  Future<void> removeTextBookmark(int page) async {
    final List<String> current = _prefs.getStringList(_keyTextBookmarks) ?? [];
    current.remove(page.toString());
    await _prefs.setStringList(_keyTextBookmarks, current);
  }

  List<int> getTextBookmarks() {
    final List<String> raw = _prefs.getStringList(_keyTextBookmarks) ?? [];
    return raw.map((e) => int.parse(e)).toList()..sort();
  }

  bool isPageBookmarked(int page) {
    final List<String> current = _prefs.getStringList(_keyTextBookmarks) ?? [];
    return current.contains(page.toString());
  }

  // --- Audio Bookmarks ---

  Future<void> addAudioBookmark(String chapterId, int timeMs, String label) async {
    final List<String> current = _prefs.getStringList(_keyAudioBookmarks) ?? [];
    final bookmark = {
      'chapter': chapterId,
      'time': timeMs,
      'label': label,
      'date': DateTime.now().toIso8601String(),
    };
    current.add(json.encode(bookmark));
    await _prefs.setStringList(_keyAudioBookmarks, current);
  }

  List<Map<String, dynamic>> getAudioBookmarks() {
    final List<String> raw = _prefs.getStringList(_keyAudioBookmarks) ?? [];
    return raw.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }
}
