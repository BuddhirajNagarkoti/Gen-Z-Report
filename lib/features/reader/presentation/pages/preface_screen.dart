import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../widgets/citable_text_view.dart';
import '../../../../core/services/language_service.dart';

class PrefaceScreen extends StatefulWidget {
  const PrefaceScreen({super.key});

  @override
  State<PrefaceScreen> createState() => _PrefaceScreenState();
}

class _PrefaceScreenState extends State<PrefaceScreen> {
  final List<String> _pages = [];
  final PageController _pageController = PageController();
  final ScrollController _innerScrollController = ScrollController();
  final LanguageService _langService = getIt<LanguageService>();
  double _fontSize = 18.0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPreface();
    _loadPreface();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _innerScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreface() async {
    try {
      const path = 'texts/texts np/preface.txt';
      final text = await rootBundle.loadString(path);
      final lines = text.split('\n');
      final List<String> paged = [];
      
      const int linesPerPage = 20;
      for (var i = 0; i < lines.length; i += linesPerPage) {
        final end = (i + linesPerPage < lines.length) ? i + linesPerPage : lines.length;
        paged.add(lines.sublist(i, end).join('\n'));
      }

      if (mounted) {
        setState(() {
          _pages.clear();
          _pages.addAll(paged);
        });
      }
    } catch (e) {
      print('Load Preface Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _pages.isEmpty 
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
                  itemCount: _pages.length,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                    if (_innerScrollController.hasClients) _innerScrollController.jumpTo(0);
                  },
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      controller: index == _currentPage ? _innerScrollController : null,
                      padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 100.0), // Padding for sticky header and page jumper
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: CitableTextView(
                            content: _pages[index],
                            fontSize: _fontSize,
                          ),
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
                        onPressed: () => context.pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'प्राक्कथन',
                        style: theme.textTheme.titleSmall?.copyWith(
                          letterSpacing: 0.5, 
                          fontWeight: FontWeight.normal
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_fields_rounded, size: 20),
                        onPressed: () => setState(() => _fontSize = (_fontSize == 18.0 ? 22.0 : 18.0)),
                        visualDensity: VisualDensity.compact,
                      ),
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
                          Icons.menu_book_rounded,
                          size: 12,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PAGE ${_currentPage + 1} / ${_pages.length}',
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
            ],
          ),
    );
  }
}
