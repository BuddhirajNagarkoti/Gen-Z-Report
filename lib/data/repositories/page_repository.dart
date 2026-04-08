import 'package:flutter/services.dart';
import '../datasources/toc_data.dart';

class PageRepository {
  final Map<int, List<String>> _npCache = {};
  final Map<int, List<String>> _enCache = {};
  bool _isInitialized = false;

  static const List<String> _allFiles = [
    '1-4.txt', '5-16.txt', '17-99.txt', '100-103.txt', '104-131.txt',
    '132-181.txt', '182-231.txt', '232-298.txt', '299-350.txt', '351-400.txt',
    '401-450.txt', '451-500.txt', '501-550.txt', '551-600.txt', '601-650.txt',
    '651-661.txt', '662-711.txt', '712-750.txt', '751-800.txt', '800-850.txt',
    '850-898.txt',
  ];
  
  final Set<String> _loadedFiles = {};

  Future<void> initialize({int? initialPage}) async {
    if (_isInitialized) return;
    
    try {
      // 1. Determine priority files (Current page + First few pages for instant engagement)
      final Set<String> priority = {'1-4.txt', '5-16.txt'};
      if (initialPage != null) {
        priority.add(getPageFile(initialPage));
      }

      // 2. Load priority files immediately to "unblock" the UI
      for (final file in priority) {
        if (!_loadedFiles.contains(file)) {
          await _parseRawText('texts/texts np/$file', _npCache);
          _loadedFiles.add(file);
        }
      }
      
      _isInitialized = true;
      
      // 3. Load everything else in the background without awaiting
      _loadRemaining();
    } catch (e) {
      // ignore
      _isInitialized = true;
    }
  }

  void _loadRemaining() async {
    for (final file in _allFiles) {
      if (!_loadedFiles.contains(file)) {
        // Use a small delay between files if needed to keep UI smooth, 
        // though microtasks are usually fine.
        await _parseRawText('texts/texts np/$file', _npCache);
        _loadedFiles.add(file);
      }
    }
  }

  String getPageFile(int page) {
    if (page >= 1 && page <= 4) return '1-4.txt';
    if (page >= 5 && page <= 16) return '5-16.txt';
    if (page >= 17 && page <= 99) return '17-99.txt';
    if (page >= 100 && page <= 103) return '100-103.txt';
    if (page >= 104 && page <= 131) return '104-131.txt';
    if (page >= 132 && page <= 181) return '132-181.txt';
    if (page >= 182 && page <= 231) return '182-231.txt';
    if (page >= 232 && page <= 298) return '232-298.txt';
    if (page >= 299 && page <= 350) return '299-350.txt';
    if (page >= 351 && page <= 400) return '351-400.txt';
    if (page >= 401 && page <= 450) return '401-450.txt';
    if (page >= 451 && page <= 500) return '451-500.txt';
    if (page >= 501 && page <= 550) return '501-550.txt';
    if (page >= 551 && page <= 600) return '551-600.txt';
    if (page >= 601 && page <= 650) return '601-650.txt';
    if (page >= 651 && page <= 661) return '651-661.txt';
    if (page >= 662 && page <= 711) return '662-711.txt';
    if (page >= 712 && page <= 750) return '712-750.txt';
    if (page >= 751 && page <= 800) return '751-800.txt';
    if (page >= 801 && page <= 850) return '800-850.txt';
    if (page >= 851 && page <= 898) return '850-898.txt';
    return '1-4.txt';
  }

  Future<void> _parseRawText(String assetPath, Map<int, List<String>> cache) async {
    try {
      final text = await rootBundle.loadString(assetPath);
      final lines = text.split('\n');
      final pageMarkerRegex = RegExp(r'^\s+([०-९0-9]+)\s*$');

      int currentPageNum = -1;
      StringBuffer content = StringBuffer();

      for (var line in lines) {
        final match = pageMarkerRegex.firstMatch(line);
        if (match != null) {
          final foundPageNum = _toArabic(match.group(1)!);
          cache[foundPageNum] = content.toString().trim().split('\n');
          content = StringBuffer();
          currentPageNum = foundPageNum + 1;
        } else {
          content.writeln(line);
        }
      }
      if (content.isNotEmpty && currentPageNum != -1) {
        final existing = cache[currentPageNum] ?? [];
        cache[currentPageNum] = [
          ...existing,
          ...content.toString().trim().split('\n')
        ];
      }
    } catch (_) {
      // file missing or parse error — skip quietly
    }
  }

  int _toArabic(String text) {
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9०-९]'), '');
    if (digitsOnly.isEmpty) return 0;
    
    const np = '०१२३४५६७८९';
    const ar = '0123456789';
    String result = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      int idx = np.indexOf(digitsOnly[i]);
      result += idx != -1 ? ar[idx] : digitsOnly[i];
    }
    return int.tryParse(result) ?? 0;
  }

  String getPageContent(int pageNum, {String lang = 'np'}) {
    final cache = lang == 'en' ? _enCache : _npCache;
    final lines = cache[pageNum];
    if (lines == null || lines.isEmpty) {
      return (lang == 'en'
          ? 'Page $pageNum content not found.'
          : 'पृष्ठ $pageNum को सामग्री फेला परेन।');
    }
    return lines.join('\n');
  }

  /// Returns the lines for a specific page.
  List<String> getPageLines(int pageNum, {String lang = 'np'}) {
    final cache = lang == 'en' ? _enCache : _npCache;
    return cache[pageNum] ?? [];
  }

  /// Finds the chapter/section title for a given page number.
  String getCategoryForPage(int pageNum) {
    if (pageNum <= 0) return 'Intro';
    
    String currentMatch = 'Preliminary';
    
    // Recursive search to find deepest nested match
    void check(dynamic toc) {
      if (toc is List) {
        for (final item in toc) {
          if (item.startPage <= pageNum) {
            currentMatch = item.englishTitle;
            if (item.sections != null) {
              check(item.sections);
            }
          }
        }
      }
    }

    check(reportToc);
    return currentMatch;
  }

  /// Searches BOTH caches (NP + EN) and returns the best-scoring pages.
  /// Returns an empty list if nothing scores above [minScore].
  List<Map<String, dynamic>> searchPages(
    String query, {
    int limit = 6,
    double minScore = 1.0,
  }) {
    if (query.isEmpty) return [];

    final tokens = _buildTokens(query);
    if (tokens.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    _searchInCache(_enCache, tokens, results, 'en');
    _searchInCache(_npCache, tokens, results, 'np');

    // Deduplicate by page — keep highest score per page
    final byPage = <int, Map<String, dynamic>>{};
    for (var r in results) {
      final page = r['page'] as int;
      if (!byPage.containsKey(page) ||
          (r['score'] as double) > (byPage[page]!['score'] as double)) {
        byPage[page] = r;
      }
    }

    final sorted = byPage.values.toList()
      ..sort((a, b) =>
          (b['score'] as double).compareTo(a['score'] as double));

    // Filter by minimum score to avoid low-confidence hallucination traps
    final filtered = sorted.where((r) => r['score'] >= minScore).toList();

    // For each top result, also include the adjacent page if available
    // so we never cut off mid-sentence context
    final pageSet = <int>{};
    final expanded = <Map<String, dynamic>>[];
    for (final r in filtered.take(limit)) {
      final page = r['page'] as int;
      final lang = r['lang'] as String;
      final cache = lang == 'en' ? _enCache : _npCache;

      if (!pageSet.contains(page)) {
        expanded.add(r);
        pageSet.add(page);
      }
      // Add next page as supporting context if it exists
      if (!pageSet.contains(page + 1) && cache.containsKey(page + 1)) {
        expanded.add({
          'page': page + 1,
          'content': cache[page + 1]!,
          'score': (r['score'] as double) * 0.7, // lower priority
          'lang': lang,
        });
        pageSet.add(page + 1);
      }
    }

    expanded.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return expanded.take(limit).toList();
  }

  Set<String> _buildTokens(String query) {
    final tokens = <String>{};

    // Normalise: lowercase + strip punctuation
    final normalised = query
        .toLowerCase()
        .replaceAll(RegExp('[।,.!?;:\'"()॥]'), ' ');

    // Split on whitespace — keep tokens ≥ 2 chars
    final words = normalised.split(RegExp(r'\s+'));
    for (final w in words) {
      if (w.length >= 2) tokens.add(w);
    }

    // Add transliterations (EN → NP equivalents)
    final extra = <String>{};
    for (final t in tokens) {
      final np = _enToNp[t];
      if (np != null) extra.add(np);
    }
    tokens.addAll(extra);

    // Also add Nepali → English equivalents so NP queries can hit EN cache
    for (final t in List.of(tokens)) {
      final en = _npToEn[t];
      if (en != null) extra.add(en);
    }
    tokens.addAll(extra);

    return tokens;
  }

  void _searchInCache(
    Map<int, List<String>> cache,
    Set<String> tokens,
    List<Map<String, dynamic>> results,
    String lang,
  ) {
    for (final entry in cache.entries) {
      final pageContent = entry.value.join('\n');
      final contentLower = pageContent.toLowerCase();
      double score = 0;

      for (final token in tokens) {
        if (contentLower.contains(token)) {
          score += 1.0;
          // Bonus for repeated occurrences
          final count = RegExp(RegExp.escape(token)).allMatches(contentLower).length;
          if (count > 2) score += 0.5;
          if (count > 5) score += 0.5;
        }
      }

      if (score > 0) {
        results.add({
          'page': entry.key,
          'content': pageContent,
          'lines': entry.value,
          'score': score,
          'lang': lang,
          'category': getCategoryForPage(entry.key),
        });
      }
    }
  }

  // ── Translation dictionaries ─────────────────────────────────────────────

  static const Map<String, String> _enToNp = {
    // People
    'kp': 'केपी',
    'oli': 'ओली',
    'rabi': 'रबि',
    'lamichhane': 'लामिछाने',
    'balen': 'बालेन',
    'shah': 'शाह',
    'prachanda': 'प्रचण्ड',
    'deuba': 'देउवा',
    'sher': 'शेर',
    // Key nouns
    'report': 'प्रतिवेदन',
    'protest': 'प्रदर्शन',
    'demonstration': 'प्रदर्शन',
    'police': 'प्रहरी',
    'arrest': 'पक्राउ',
    'killed': 'मारिए',
    'death': 'मृत्यु',
    'deaths': 'मृत्यु',
    'injured': 'घाइते',
    'bullet': 'गोली',
    'fire': 'गोली',
    'firing': 'गोलीबारी',
    'gun': 'बन्दुक',
    'rounds': 'राउन्ड',
    'total': 'कुल',
    'statement': 'बयान',
    'government': 'सरकार',
    'parliament': 'संसद',
    'minister': 'मन्त्री',
    'prime': 'प्रधान',
    'human': 'मानव',
    'rights': 'अधिकार',
    'commission': 'आयोग',
    'investigation': 'अनुसन्धान',
    'army': 'सेना',
    'youth': 'युवा',
    'student': 'विद्यार्थी',
    'hospital': 'अस्पताल',
    'cctv': 'सिसिटिभी',
    'evidence': 'प्रमाण',
    'witness': 'साक्षी',
    'court': 'अदालत',
    'media': 'मिडिया',
    'social': 'सामाजिक',
    'nepal': 'नेपाल',
    'kathmandu': 'काठमाडौं',
    'lalitpur': 'ललितपुर',
  };

  static const Map<String, String> _npToEn = {
    'प्रहरी': 'police',
    'प्रदर्शन': 'protest',
    'सरकार': 'government',
    'प्रतिवेदन': 'report',
    'गोली': 'bullet',
    'मृत्यु': 'death',
    'घाइते': 'injured',
    'अनुसन्धान': 'investigation',
    'अधिकार': 'rights',
    'युवा': 'youth',
    'काठमाडौं': 'kathmandu',
    'नेपाल': 'nepal',
    'संसद': 'parliament',
    'अदालत': 'court',
  };

  int get totalPages => 898;
  bool get isFullReportIndexed =>
      _npCache.length >= 800 || _enCache.length >= 800;
}
