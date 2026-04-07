import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
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
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  try {
    final prefs = await SharedPreferences.getInstance();
    await setupDependencyInjection(prefs);
    
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
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
              displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
              headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: Colors.black, height: 1.6),
              bodyMedium: TextStyle(color: Color(0xFF424245), height: 1.6),
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
              displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: Colors.white, height: 1.6),
              bodyMedium: TextStyle(color: Color(0xFFAEAEB2), height: 1.6),
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
    final theme = Theme.of(context);
    
    return Scaffold(
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;
          
          return Stack(
            children: [
              // Premium Paper Background Texture
              Positioned.fill(
                child: Container(
                  color: isDark ? const Color(0xFF121214) : const Color(0xFFF9F7F2), // Warm paper tone
                  child: CustomPaint(
                    painter: _PaperTexturePainter(
                      isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: MiniAudioPlayer(),
              ),
              SelectionArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'जियनजेड प्रतिवेदन २०८२',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            fontSize: 44,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // More elegant divider
                        Container(
                          width: 120,
                          height: 1.5,
                          color: theme.colorScheme.primary.withOpacity(0.15),
                        ),
                        const SizedBox(height: 80),
                        // Reordered & Refined Button Group
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Column(
                            children: [
                              _HomeMenuButton(
                                label: 'प्राक्कथन',
                                description: 'Preface & Introduction',
                                icon: Icons.history_edu_rounded,
                                onPressed: () => context.push('/preface'),
                              ),
                              const SizedBox(height: 16),
                              _HomeMenuButton(
                                label: 'विषयसूची',
                                description: 'Table of Contents',
                                icon: Icons.format_list_bulleted_rounded,
                                onPressed: () => context.push('/toc'),
                              ),
                              const SizedBox(height: 16),
                              _HomeMenuButton(
                                label: 'पूर्ण प्रतिवेदन',
                                description: 'Read the full report',
                                icon: Icons.menu_book_rounded,
                                onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final lastPage = prefs.getInt('last_read_page') ?? 1;
                            if (context.mounted) {
                              context.push('/reader?page=$lastPage');
                            }
                          },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                        Text(
                          'जेनजी आन्दोलन जाँचबुझ आयोगको प्रतिवेदन',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            height: 1.8,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  onPressed: () {
                    themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  final Color color;
  _PaperTexturePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final random = math.Random(42);
    // Draw subtle fibers/grain
    for (var i = 0; i < 1500; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final length = random.nextDouble() * 3 + 1;
      final angle = random.nextDouble() * 2 * math.pi;
      
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x1 + math.cos(angle) * length, y1 + math.sin(angle) * length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeMenuButton extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  const _HomeMenuButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary.withOpacity(0.8)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, 
              size: 14, 
              color: theme.colorScheme.primary.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
