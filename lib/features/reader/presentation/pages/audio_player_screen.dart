import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:math' as math;
import '../../../../core/services/audio_manager.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;

  const AudioPlayerScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  final _audioManager = GetIt.instance<AudioManager>();

  bool _showPlaylist = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    
    _updateRotation();
    _audioManager.addListener(_updateRotation);
  }

  void _updateRotation() {
    if (_audioManager.isPlaying || _audioManager.isLoading) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _audioManager.removeListener(_updateRotation);
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'वाचन भइरहेको छ',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _audioManager.isActive && _audioManager.downloadProgress < 1.0 
                ? Icons.downloading_rounded 
                : Icons.download_for_offline_rounded,
              color: _audioManager.downloadProgress > 0 && _audioManager.downloadProgress < 1.0 
                ? theme.colorScheme.primary 
                : null,
            ),
            onPressed: () => _audioManager.downloadCurrentPage(),
            tooltip: 'Download for offline',
          ),
          IconButton(
            icon: Icon(_showPlaylist ? Icons.close_rounded : Icons.queue_music_rounded),
            onPressed: () => setState(() => _showPlaylist = !_showPlaylist),
            tooltip: 'Show All Pages',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _audioManager,
        builder: (context, _) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // LOADING STRIP (Only visible during loading)
                          if (_audioManager.isLoading)
                            SizedBox(
                              width: 280,
                              height: 280,
                              child: CircularProgressIndicator(
                                value: _audioManager.downloadProgress > 0 && _audioManager.downloadProgress < 1 ? _audioManager.downloadProgress : null,
                                strokeWidth: 2,
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                          
                          // LIGHT STRIP (GLOW)
                          if (_audioManager.isLoading)
                            AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationController.value * 2 * math.pi,
                                  child: Container(
                                    width: 270,
                                    height: 270,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          theme.colorScheme.primary.withOpacity(0),
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withOpacity(0),
                                        ],
                                        stops: const [0.4, 0.5, 0.6],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // CIRCULAR SPINNING "CD" CAROUSEL
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                                gradient: SweepGradient(
                                  center: Alignment.center,
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.05),
                                    theme.colorScheme.primary.withOpacity(0.15),
                                    theme.colorScheme.primary.withOpacity(0.05),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.scaffoldBackgroundColor,
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withOpacity(0.2),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // TITLE & SUBTITLE
                    Text(
                      'पृष्ठ ${_audioManager.currentPage}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.chapterTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // PROGRESS BAR
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: theme.colorScheme.primary,
                            inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.1),
                            thumbColor: theme.colorScheme.primary,
                          ),
                          child: Slider(
                            value: _audioManager.duration.inSeconds > 0 
                              ? _audioManager.position.inSeconds.toDouble().clamp(0.0, _audioManager.duration.inSeconds.toDouble())
                              : 0.0,
                            max: _audioManager.duration.inSeconds > 0 
                              ? _audioManager.duration.inSeconds.toDouble()
                              : 1.0,
                            onChanged: (value) {
                              _audioManager.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_audioManager.position),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                _formatDuration(_audioManager.duration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // CONTROLS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, size: 32),
                          onPressed: () => _audioManager.seek(_audioManager.position - const Duration(seconds: 10)),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                          child: _audioManager.isLoading 
                            ? Center(
                                child: CircularProgressIndicator(
                                  value: _audioManager.downloadProgress > 0 ? _audioManager.downloadProgress : null,
                                  color: theme.colorScheme.onPrimary,
                                  strokeWidth: 3,
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  _audioManager.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 48,
                                ),
                                onPressed: () {
                                  if (_audioManager.isPlaying) {
                                    _audioManager.pause();
                                  } else {
                                    _audioManager.resume();
                                  }
                                },
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded, size: 32),
                          onPressed: () => _audioManager.seek(_audioManager.position + const Duration(seconds: 10)),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              
              // OVERLAY PLAYLIST
              if (_showPlaylist)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: GestureDetector(
                      onTap: () => setState(() => _showPlaylist = false),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              
              if (_showPlaylist)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'उपलब्ध वाचन पृष्ठहरू',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: 99, // We have 99 voice files
                            itemBuilder: (context, index) {
                              // Mapping based on your files: 1-35, 648-711
                              int pageNum;
                              if (index < 35) {
                                pageNum = index + 1;
                              } else {
                                pageNum = 648 + (index - 35);
                              }
                              
                              final isCurrent = _audioManager.currentPage == pageNum;
                              
                              return ListTile(
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pageNum',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : theme.colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'पृष्ठ $pageNum को वाचन',
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                                trailing: isCurrent && _audioManager.isPlaying 
                                  ? Icon(Icons.volume_up_rounded, color: theme.colorScheme.primary)
                                  : null,
                                onTap: () {
                                  _audioManager.playPage(pageNum);
                                  setState(() => _showPlaylist = false);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
