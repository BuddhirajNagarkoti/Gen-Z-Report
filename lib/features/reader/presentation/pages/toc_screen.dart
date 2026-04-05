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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('विषयसूची'),
        elevation: 0,
        actions: const [
          SizedBox.shrink(),
        ],
      ),
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
                      return ListView.builder(
                        controller: pageIdx == _currentPage ? _innerScrollController : null,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                    widget.onChapterSelected(pageNum);
                                    Navigator.pop(context);
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: Text(
                        'विषयसूची पाना ${_currentPage + 1} / ${_tocPages.length}',
                        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2),
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
