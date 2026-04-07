import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/audio_manager.dart';
import '../../../../core/di/service_locator.dart';

class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioManager = getIt<AudioManager>();

    return ListenableBuilder(
      listenable: audioManager,
      builder: (context, _) {
        if (!audioManager.isActive) return const SizedBox.shrink();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: InkWell(
              onTap: () {
                context.push('/audio?title=GEN Z Report');
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.audiotrack,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            audioManager.isLoading && audioManager.statusMessage.isNotEmpty
                                ? audioManager.statusMessage
                                : 'पृष्ठ ${audioManager.currentPage} को रेकर्डिङ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: audioManager.isLoading ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: audioManager.duration.inMilliseconds > 0
                                  ? audioManager.position.inMilliseconds /
                                      audioManager.duration.inMilliseconds
                                  : 0,
                              backgroundColor:
                                  Theme.of(context).colorScheme.outline.withOpacity(0.1),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (audioManager.isPlaying) {
                          audioManager.pause();
                        } else {
                          audioManager.resume();
                        }
                      },
                      icon: Icon(
                        audioManager.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSpeedMenu(context, audioManager),
                      icon: Text(
                        '${audioManager.playbackSpeed.toStringAsFixed(1)}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      tooltip: 'गति चयन गर्नुहोस्',
                    ),
                    IconButton(
                      onPressed: () => audioManager.stop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSpeedMenu(BuildContext context, AudioManager audioManager) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'प्लेब्याक गति',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...speeds.map((speed) => ListTile(
              title: Text('${speed}x', textAlign: TextAlign.center),
              selected: audioManager.playbackSpeed == speed,
              onTap: () {
                audioManager.setPlaybackSpeed(speed);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
