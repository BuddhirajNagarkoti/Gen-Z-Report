import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/audio_manager.dart';

class AudioControlBar extends StatelessWidget {
  const AudioControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    final audioManager = GetIt.instance<AudioManager>();

    return ListenableBuilder(
      listenable: audioManager,
      builder: (context, _) {
        if (!audioManager.isActive) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: theme.dividerColor.withOpacity(0.05), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: audioManager.duration.inSeconds > 0 
                      ? audioManager.position.inSeconds / audioManager.duration.inSeconds 
                      : 0.0,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    minHeight: 2,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              audioManager.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            onPressed: () {
                              if (audioManager.isPlaying) {
                                audioManager.pause();
                              } else {
                                audioManager.resume();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                audioManager.isPlaying ? 'जियनजेड प्रतिवेदन पढेको...' : 'वाचन रोकिएको छ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'पृष्ठ ${audioManager.currentPage} वाचन भइरहेको छ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                          onPressed: () => audioManager.stop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
