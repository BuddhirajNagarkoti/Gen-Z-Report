import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/language_service.dart';
import '../widgets/mini_audio_player.dart';

class TOCScreen extends StatefulWidget {
  final Function(int) onChapterSelected;
  const TOCScreen({super.key, required this.onChapterSelected});

  @override
  State<TOCScreen> createState() => _TOCScreenState();
}

class _TOCScreenState extends State<TOCScreen> {
  final LanguageService _langService = getIt<LanguageService>();
  final List<List<String>> _tocPages = [];
  final PageController _pageController = PageController();
  final ScrollController _innerScrollController = ScrollController();
  bool _isLoading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadTOC();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _innerScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTOC() async {
    setState(() {
      _isLoading = true;
      _tocPages.clear();
    });
    
    try {
      const path = 'texts/texts np/toc.txt';
      final content = await rootBundle.loadString(path);
      final lines = content.split('\n').where((l) {
        final tl = l.trim();
        if (tl.isEmpty) return false;
        if (tl == 'विषयसूची' || tl == 'CONTENTS' || tl == 'Table of Contents') return false;
        if (RegExp(r'^\s*\d+\s*$').hasMatch(l)) return false;
        return true;
      }).toList();

      // Split into pages of 12 entries
      const int entriesPerPage = 12;
      for (var i = 0; i < lines.length; i += entriesPerPage) {
        final end = (i + entriesPerPage < lines.length) ? i + entriesPerPage : lines.length;
        _tocPages.add(lines.sublist(i, end));
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading TOC: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parsePageNumber(String line) {
    // Matches the LAST sequence of digits (arabic or nepali), 
    // potentially followed by trailing dots or spaces.
    final match = RegExp(r'(\d+|[०-९]+)[\s.]*$').firstMatch(line.trim());
    if (match != null) {
      final text = match.group(1)!;
      // If it contains nepali digits, convert them
      if (RegExp(r'[०-९]').hasMatch(text)) {
        return _nepaliToArabic(text);
      }
      return int.tryParse(text);
    }
    return null;
  }

  int _nepaliToArabic(String nepali) {
    const np = '०१२३४५६७८९';
    const ar = '0123456789';
    final buf = StringBuffer();
    for (final ch in nepali.characters) {
      final idx = np.indexOf(ch);
      buf.write(idx != -1 ? ar[idx] : ch);
    }
    return int.tryParse(buf.toString()) ?? 0;
  }

  String _extractTitle(String line) {
    // Strip trailing page number pattern: dots + digits (arabic or nepali)
    return line
        .replaceAll(RegExp(r'\.{2,}[\s\d०-९]*$'), '')
        .replaceAll(RegExp(r'[\s\d०-९]+$'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final pos = _innerScrollController.hasClients ? _innerScrollController.position : null;
                      final isAtBottom = pos == null || pos.extentAfter == 0;
                      final isAtTop = pos == null || pos.extentBefore == 0;
                      
                      if (pointerSignal.scrollDelta.dy > 10 && isAtBottom) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else if (pointerSignal.scrollDelta.dy < -10 && isAtTop) {
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    }
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _tocPages.length,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                      if (_innerScrollController.hasClients) _innerScrollController.jumpTo(0);
                    },
                    itemBuilder: (context, pageIdx) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView.builder(
                            controller: pageIdx == _currentPage ? _innerScrollController : null,
                            padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 120.0), // Padding for sticky header and page jumper
                            physics: const AlwaysScrollableScrollPhysics(), 
                            itemCount: _tocPages[pageIdx].length,
                            itemBuilder: (context, index) {
                              final line = _tocPages[pageIdx][index];
                              final pageNum = _parsePageNumber(line);
                              final title = _extractTitle(line);
                              final bool isRoot = line.startsWith('भाग') || line.startsWith('परिच्छेद');
                              final bool isSub = line.startsWith('  ');

                              return ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isRoot ? 16 : (isSub ? 40 : 28),
                                  right: 16,
                                ),
                                dense: !isRoot,
                                title: Text(
                                  title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                                    fontSize: isRoot ? 16 : 14,
                                    color: isRoot ? null : theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                                trailing: pageNum != null
                                    ? Text(
                                        'पृष्ठ $pageNum',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary.withOpacity(0.6),
                                          letterSpacing: 1,
                                        ),
                                      )
                                    : null,
                                onTap: pageNum != null
                                    ? () {
                                        Navigator.pop(context);
                                        widget.onChapterSelected(pageNum);
                                      }
                                    : null,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Floating Header (Matches ReaderScreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withOpacity(0.9),
                      border: Border(
                        bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.05)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          'विषयसूची',
                          style: theme.textTheme.titleSmall?.copyWith(
                            letterSpacing: 0.5, 
                            fontWeight: FontWeight.normal
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer to balance the layout
                      ],
                    ),
                  ),
                ),

                // Page Jumper (Bottom Center - Unified Style)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list_rounded,
                            size: 12,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'विषयसूची पाना ${_currentPage + 1} / ${_tocPages.length}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Positioned(
                  bottom: 70, // Above pagination bar
                  left: 0,
                  right: 0,
                  child: MiniAudioPlayer(),
                ),
              ],
            ),
    );
  }
}
