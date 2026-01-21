import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/recording_model.dart';
import '../providers/record_provider.dart';
import '../utils/format_utils.dart';

import 'package:share_plus/share_plus.dart';

class PlaybackScreen extends StatefulWidget {
  final RecordingModel recording;

  const PlaybackScreen({super.key, required this.recording});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late List<double> _staticAmplitudes;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Generate deterministic waveform based on recording ID
    final random = _DeterministicRandom(widget.recording.id.hashCode);
    _staticAmplitudes =
        List.generate(100, (index) => random.nextDouble() * 0.8 + 0.1);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xCC000000),
        middle: const Text(
          'Now Playing',
          style: TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.share, color: CupertinoColors.activeBlue),
          onPressed: () {
            Share.shareXFiles([XFile(widget.recording.path)], text: 'Shared from Voice Recorder');
          },
        ),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Header/Visualizer Info
              Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.recording.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FormatUtils.formatDate(widget.recording.date),
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Dynamic Pulse Visualizer
              Consumer<RecordProvider>(
                builder: (context, provider, child) {
                  final isPlaying = provider.isPlaying && provider.currentPlayingPath == widget.recording.path;
                  if (isPlaying && !_pulseController.isAnimating) {
                    _pulseController.repeat(reverse: true);
                  } else if (!isPlaying && _pulseController.isAnimating) {
                    _pulseController.stop();
                  }

                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = isPlaying ? 1.0 + (_pulseController.value * 0.12) : 1.0;
                      final glow = isPlaying ? _pulseController.value * 20.0 : 0.0;

                      return Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF1C1C1E),
                              CupertinoColors.black,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemRed.withValues(alpha: isPlaying ? 0.2 : 0.05),
                              blurRadius: 40 + glow,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.systemRed.withValues(alpha: isPlaying ? 0.15 : 0.05),
                                border: Border.all(
                                  color: CupertinoColors.systemRed.withValues(alpha: isPlaying ? 0.4 : 0.1),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.waveform,
                                size: 50,
                                color: isPlaying ? CupertinoColors.white : CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Persistent Waveform Visualization
              Consumer<RecordProvider>(
                builder: (context, provider, child) {
                  final position = provider.currentPosition;
                  final duration = provider.totalDuration;
                  final progress = duration.inMilliseconds > 0 
                      ? position.inMilliseconds / duration.inMilliseconds 
                      : 0.0;

                  return Column(
                    children: [
                      Container(
                        height: 60,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        child: CustomPaint(
                          painter: StaticWaveformPainter(
                            amplitudes: _staticAmplitudes,
                            progress: progress,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                      
                      // Progress Slider & Timestamps
                      Column(
                        children: [
                          CupertinoSlider(
                            activeColor: CupertinoColors.systemRed,
                            thumbColor: CupertinoColors.white,
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (val) {
                              if (duration.inMilliseconds > 0) {
                                provider.seekTo(Duration(milliseconds: (val * duration.inMilliseconds).toInt()));
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FormatUtils.formatDuration(position),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                                Text(
                                  FormatUtils.formatDuration(duration),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              // Main Playback Controls
              Consumer<RecordProvider>(
                builder: (context, provider, child) {
                  final isPlaying = provider.isPlaying && provider.currentPlayingPath == widget.recording.path;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: CupertinoIcons.gobackward_15,
                        onPressed: () => provider.seekTo(provider.currentPosition - const Duration(seconds: 15)),
                      ),
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            provider.pausePlayback();
                          } else {
                            provider.playRecording(widget.recording.path);
                          }
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.white.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                            size: 36,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      _ControlButton(
                        icon: CupertinoIcons.goforward_15,
                        onPressed: () => provider.seekTo(provider.currentPosition + const Duration(seconds: 15)),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(icon, size: 32, color: CupertinoColors.systemGrey),
    );
  }
}

class StaticWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color color;

  StaticWaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    
    final barGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFF5252), // Lighter red top
        const Color(0xFFFF3B30), // Classic red center
        const Color(0xFFFF5252), // Lighter red bottom
      ],
    );

    final activePaint = Paint()
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = CupertinoColors.systemRed.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round;

    const barWidth = 2.0;
    const gap = 3.0;
    final totalBars = amplitudes.length;
    final contentWidth = totalBars * (barWidth + gap);
    final startX = (size.width - contentWidth) / 2;

    for (int i = 0; i < totalBars; i++) {
        final barProgress = i / totalBars;
        final isPlayed = barProgress <= progress;
        
        final barHeight = amplitudes[i] * size.height;
        final x = startX + i * (barWidth + gap);
        final rect = Rect.fromLTWH(x, centerY - barHeight / 2, barWidth, barHeight);
        
        if (isPlayed) {
          activePaint.shader = barGradient.createShader(rect);
          canvas.drawLine(Offset(x + barWidth/2, centerY - barHeight/2), Offset(x + barWidth/2, centerY + barHeight/2), activePaint);
        } else {
          canvas.drawLine(Offset(x + barWidth/2, centerY - barHeight/2), Offset(x + barWidth/2, centerY + barHeight/2), inactivePaint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant StaticWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DeterministicRandom {
  int seed;
  _DeterministicRandom(this.seed);

  double nextDouble() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  }
}
