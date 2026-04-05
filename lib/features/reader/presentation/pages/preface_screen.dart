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
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('प्राक्कथन'),
        elevation: 0,
        actions: [
          const SizedBox.shrink(),
          const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => setState(() => _fontSize = (_fontSize == 18.0 ? 22.0 : 18.0)),
          ),
        ],
      ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                      child: CitableTextView(
                        content: _pages[index],
                        fontSize: _fontSize,
                      ),
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
                      'PAGE ${_currentPage + 1} / ${_pages.length}',
                      style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
