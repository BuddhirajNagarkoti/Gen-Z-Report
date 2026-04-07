import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/chapter.dart';
import '../../../../data/repositories/page_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../data/datasources/toc_data.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/citable_text_view.dart';
import '../widgets/mini_audio_player.dart';
import 'package:flutter/gestures.dart';

import '../../../../core/services/language_service.dart';
import '../../../../core/services/audio_manager.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/sync_data_service.dart';
import '../widgets/audio_control_bar.dart';
import 'toc_screen.dart';

class ReaderScreen extends StatefulWidget {
  final int initialPage;
  const ReaderScreen({super.key, this.initialPage = 1});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  final ScrollController _innerScrollController = ScrollController();
  final PageRepository _repo = getIt<PageRepository>();
  final SyncDataService _syncService = getIt<SyncDataService>();
  final AudioManager _audioManager = getIt<AudioManager>();
  final BookmarkService _bookmarkService = getIt<BookmarkService>();
  final LanguageService _langService = getIt<LanguageService>();
  
  int _currentPageIndex = 0;
  double _fontSize = 18.0;
  bool _isReady = false;
  List<int> _bookmarks = [];
  
  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPage - 1;
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadLocalStorageState();
    _initData();
    
    // Sync reader with audio manager to follow the voice
    _audioManager.addListener(_syncWithAudio);
  }

  Future<void> _loadLocalStorageState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final savedBookmarks = prefs.getStringList('bookmarks') ?? [];
      _bookmarks = savedBookmarks.map((e) => int.parse(e)).toList();
    });
  }

  Future<void> _saveLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_page', _currentPageIndex + 1);
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final pageNum = _currentPageIndex + 1;
      if (_bookmarks.contains(pageNum)) {
        _bookmarks.remove(pageNum);
      } else {
        _bookmarks.add(pageNum);
        _bookmarks.sort();
      }
      prefs.setStringList('bookmarks', _bookmarks.map((e) => e.toString()).toList());
    });
  }

  void _syncWithAudio() {
    if (_audioManager.isPlaying && mounted) {
      final audioPage = _audioManager.currentPage;
      final audioPageIndex = audioPage - 1;
      
      if (_currentPageIndex != audioPageIndex) {
        _pageController.animateToPage(
          audioPageIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _initData() async {
    await _repo.initialize();
    _loadSyncDataForCurrentPage();
    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  void _loadSyncDataForCurrentPage() {
    // synchronization disabled as per user request
  }

  void _playAudio(int pageNum) {
    _audioManager.playPage(pageNum);
    context.push('/audio?id=pg_$pageNum&title=पृष्ठ $pageNum वाचन');
  }

  void _showAudioWarning() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('अडियो बजिरहेको छ। कृपया अगाडि बढ्न पहिले अडियो रोक्नुहोस्।')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
      ),
    );
  }


  @override
  void dispose() {
    _audioManager.removeListener(_syncWithAudio);
    _pageController.dispose();
    super.dispose();
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
        title: Text(
          'जियनजेड प्रतिवेदन',
          style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 0.5, fontWeight: FontWeight.normal),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _bookmarks.contains(_currentPageIndex + 1)
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _bookmarks.contains(_currentPageIndex + 1)
                  ? theme.colorScheme.primary
                  : null,
            ),
            onPressed: _toggleBookmark,
            tooltip: 'बुकमार्क थप्नुहोस्',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => _showSettings(context),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outline.withOpacity(0.1), height: 0.5),
        ),
      ),
      drawer: _buildTOCDrawer(context),
      body: !_isReady 
        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
        : Stack(
            children: [
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    final pos = _innerScrollController.hasClients ? _innerScrollController.position : null;
                    final isAtBottom = pos == null || pos.extentAfter == 0;
                    final isAtTop = pos == null || pos.extentBefore == 0;
                    
                    if (pointerSignal.scrollDelta.dy > 10 && isAtBottom) {
                      if (_audioManager.isPlaying) {
                        _showAudioWarning();
                        return;
                      }
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else if (pointerSignal.scrollDelta.dy < -10 && isAtTop) {
                      if (_audioManager.isPlaying) {
                        _showAudioWarning();
                        return;
                      }
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  }
                },
                child: SelectionArea(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (_audioManager.isPlaying) {
                        _showAudioWarning();
                      }
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _audioManager.isPlaying 
                          ? const NeverScrollableScrollPhysics() 
                          : const BouncingScrollPhysics(),
                      itemCount: _repo.totalPages,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                        _innerScrollController.jumpTo(0);
                        _loadSyncDataForCurrentPage();
                        _saveLastReadPage();
                      },
                      itemBuilder: (context, index) {
                        return _buildPage(context, index + 1);
                      },
                    ),
                  ),
                ),
              ),
              _buildStickyHeader(context),
              Positioned(
                bottom: 80, 
                left: 0,
                right: 0,
                child: const MiniAudioPlayer(),
              ),
            ],
          ),
    );
  }

  Widget _buildPage(BuildContext context, int pageNum) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        controller: pageNum == _currentPageIndex + 1 ? _innerScrollController : null,
        padding: const EdgeInsets.fromLTRB(16.0, 70.0, 16.0, 40.0), // Top padding for sticky header
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
            if ([11, 12, 13, 487, 488, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606].contains(pageNum)) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/Page-$pageNum.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
            CitableTextView(
              content: _repo.getPageContent(pageNum, lang: 'np'),
              fontSize: _fontSize,
            ),
            const SizedBox(height: 120), // Reserve space for overlay
          ],
        ),
      ),
    ),
  ),
);
}

  List<Widget> _buildCitableContent(BuildContext context, String content) {
    return [];
  }

  Widget _buildStickyHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageNum = _currentPageIndex + 1;
    
    return Positioned(
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
            // Page Jumper (Top Left)
            GestureDetector(
              onTap: () => _showJumpToPageDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 12,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pageNum / ${_repo.totalPages}',
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
            
            // Audio Controls (Top Right)
            ListenableBuilder(
              listenable: _audioManager,
              builder: (context, _) {
                final bool isSamePage = _audioManager.currentPage == pageNum;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_audioManager.isLoading && isSamePage)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          _audioManager.isPlaying && isSamePage 
                            ? Icons.pause_circle_outline 
                            : Icons.play_circle_outline, 
                          size: 20,
                          color: _audioManager.isAudioAvailable(pageNum) ? null : theme.colorScheme.onSurface.withOpacity(0.15),
                        ),
                        onPressed: _audioManager.isAudioAvailable(pageNum) 
                          ? () {
                            if (_audioManager.isPlaying && isSamePage) {
                              _audioManager.pause();
                            } else {
                              _playAudio(pageNum);
                            }
                          }
                          : null,
                        tooltip: _audioManager.isAudioAvailable(pageNum) ? 'वाचन सुन्नुहोस्' : 'यो पृष्ठको लागि अडियो उपलब्ध छैन',
                        visualDensity: VisualDensity.compact,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _audioManager.isPlaying && isSamePage ? 'सुन्दै हुनुहुन्छ...' : 'पृष्ठ $pageNum',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTOCDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logos/app_logo.jpg',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                Text(
                  'जियनजेड प्रतिवेदन',
                  style: textTheme.titleSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'अनुसन्धान प्रतिवेदन २०८२',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, size: 20),
            title: const Text('प्राक्कथन'),
            onTap: () => context.push('/preface'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, size: 20),
            title: const Text('विषयसूची'),
            onTap: () {
              // Close the drawer first, then open TOC as a local modal.
              // This gives the TOC screen a direct reference to _pageController
              // so tapping a chapter actually moves the reader — not a new instance.
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => TOCScreen(
                    onChapterSelected: (page) {
                      _pageController.jumpToPage(page - 1);
                      setState(() => _currentPageIndex = page - 1);
                    },
                  ),
                ),
              );
            },
          ),
          if (_bookmarks.isNotEmpty) ...[
            const Divider(height: 32, indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'बुकमार्क गरिएका पृष्ठहरू',
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 2, 
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._bookmarks.map((pageNum) => ListTile(
              leading: const Icon(Icons.bookmark_rounded, size: 18),
              title: Text('पृष्ठ $pageNum'),
              dense: true,
              onTap: () {
                _pageController.jumpToPage(pageNum - 1);
                setState(() => _currentPageIndex = pageNum - 1);
                Navigator.pop(context);
              },
            )),
          ],
          const Divider(height: 32, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'अध्यायहरू',
              style: textTheme.labelSmall?.copyWith(letterSpacing: 2, color: colorScheme.onSurface.withOpacity(0.5)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: reportToc.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final chapter = reportToc[index];
                final isPart = chapter.id.startsWith('part');
                
                return ListTile(
                  contentPadding: EdgeInsets.only(left: isPart ? 16 : 32, right: 16),
                  title: Text(
                    chapter.getDisplayTitle(false),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: isPart ? 15 : 14,
                      fontWeight: isPart ? FontWeight.bold : FontWeight.normal,
                      color: isPart ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  onTap: () {
                    _pageController.jumpToPage(chapter.startPage - 1);
                    setState(() => _currentPageIndex = chapter.startPage - 1);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // We'll handle color inside the builder
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;
          // Dynamically fetch the theme based on current mode
          // This ensures the modal updates instantly when the switch is toggled
          final theme = isDark 
            ? ThemeData.dark().copyWith(
                textTheme: GoogleFonts.muktaTextTheme(ThemeData.dark().textTheme),
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark)
              ) 
            : ThemeData.light().copyWith(
                textTheme: GoogleFonts.muktaTextTheme(ThemeData.light().textTheme),
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light)
              );
              
          // Alternative: Use the current context's theme if main.dart is already updating it
          // But since the modal is its own route, we're safer fetching it explicitly or 
          // letting the inherited widget handle it if we remove the static color.
          
          final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
          final onBgColor = isDark ? Colors.white : Colors.black87;

          return StatefulBuilder(
            builder: (context, setModalState) => Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'पठन सेटिङहरू',
                    style: theme.textTheme.titleSmall?.copyWith(
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                      color: onBgColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Icon(Icons.format_size, size: 20, color: onBgColor.withOpacity(0.6)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14,
                          max: 32,
                          activeColor: theme.colorScheme.primary,
                          inactiveColor: onBgColor.withOpacity(0.1),
                          onChanged: (val) {
                            setModalState(() {
                              _fontSize = val;
                            });
                            setState(() {
                              _fontSize = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'राती मोड',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          color: onBgColor,
                        ),
                      ),
                      Switch(
                        value: isDark,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (bool value) {
                          themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJumpToPageDialog(BuildContext context) {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'पृष्ठमा जानुहोस्',
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2.5),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 – ${_repo.totalPages}',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          onSubmitted: (val) {
            final page = int.tryParse(val);
            if (page != null && page >= 1 && page <= _repo.totalPages) {
              _pageController.jumpToPage(page - 1);
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('रद्द गर्नुहोस्', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1)),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _repo.totalPages) {
                _pageController.jumpToPage(page - 1);
                Navigator.of(ctx).pop();
              }
            },
            child: Text('जानुहोस्', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
