import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/reader/presentation/pages/reader_screen.dart';
import 'features/reader/presentation/pages/preface_screen.dart';
import 'features/reader/presentation/pages/toc_screen.dart';
import 'features/reader/presentation/pages/audio_player_screen.dart';
import 'core/di/service_locator.dart';
import 'core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/reader/presentation/widgets/mini_audio_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final prefs = await SharedPreferences.getInstance();
    await setupDependencyInjection(prefs);
    
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBk-2EN4Fz46o-sRaOSFYZFVbkNSKPudVY',
          appId: '1:503736301410:web:997c06969ddf09d1dd5e3b',
          messagingSenderId: '503736301410',
          projectId: 'gen-z-report',
          storageBucket: 'gen-z-report.firebasestorage.app',
          authDomain: 'gen-z-report.firebaseapp.com',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print('Initialization failed: $e');
  }
  
  runApp(const GenZReportApp());
}

class GenZReportApp extends StatelessWidget {
  const GenZReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp.router(
          title: 'जियनजेड प्रतिवेदन २०८२',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF000000),
              onPrimary: Color(0xFFFFFFFF),
              surface: Color(0xFFF9F9F9),
              onSurface: Color(0xFF1D1D1F),
              outline: Color(0xFFE5E5EA),
            ),
            textTheme: GoogleFonts.muktaTextTheme().copyWith(
              displayLarge: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              bodyLarge: const TextStyle(color: Colors.black, height: 1.6),
              bodyMedium: const TextStyle(color: Color(0xFF424245), height: 1.6),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFFFFF),
              onPrimary: Color(0xFF000000),
              surface: Color(0xFF1C1C1E),
              onSurface: Color(0xFFF5F5F7),
              outline: Color(0xFF38383A),
            ),
            textTheme: GoogleFonts.muktaTextTheme(ThemeData.dark().textTheme).copyWith(
              displayLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              bodyLarge: const TextStyle(color: Colors.white, height: 1.6),
              bodyMedium: const TextStyle(color: Color(0xFFAEAEB2), height: 1.6),
            ),
          ),
          routerConfig: _router,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/reader',
      builder: (context, state) {
        final page = int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
        return ReaderScreen(initialPage: page);
      },
    ),
    GoRoute(
      path: '/toc',
      builder: (context, state) => TOCScreen(
        onChapterSelected: (page) => context.push('/reader?page=$page'),
      ),
    ),
    GoRoute(
      path: '/preface',
      builder: (context, state) => const PrefaceScreen(),
    ),
    GoRoute(
      path: '/audio',
      builder: (context, state) {
        final chapterId = state.uri.queryParameters['id'] ?? '1-4';
        final title = state.uri.queryParameters['title'] ?? 'अध्याय';
        return AudioPlayerScreen(chapterId: chapterId, chapterTitle: title);
      },
    ),
  ],
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'जियनजेड प्रतिवेदन २०८२',
                  style: textTheme.displayLarge?.copyWith(
                    letterSpacing: 0.5,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1, width: 40, color: colorScheme.primary),
                const SizedBox(height: 48),
                Text(
                  'न्यूनतम अनुसन्धान पाठक',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 80),
                _HomeAction(
                  label: 'प्राक्कथन पढ्नुहोस्',
                  onTap: () => context.push('/preface'),
                ),
                const SizedBox(height: 16),
                _HomeAction(
                  label: 'विषयसूची',
                  onTap: () => context.push('/toc'),
                ),
                const SizedBox(height: 48),
                OutlinedButton(
                  onPressed: () => context.push('/reader'),
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    side: BorderSide(color: colorScheme.primary.withOpacity(0.2), width: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  ),
                  child: Text(
                    'अनुसन्धान प्रवेश गर्नुहोस्',
                    style: textTheme.titleLarge?.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: MiniAudioPlayer(),
          ),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HomeAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
