import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/record_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/waveform_widget.dart';
import 'recordings_list_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
          child: Consumer<RecordProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Voice Recorder',
                          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              );
                            },
                            child: Icon(
                              (provider.isRecording || provider.isPaused) 
                                  ? CupertinoIcons.xmark 
                                  : CupertinoIcons.list_bullet, 
                              key: ValueKey((provider.isRecording || provider.isPaused) ? 'cancel' : 'list'),
                              color: (provider.isRecording || provider.isPaused)
                                  ? CupertinoColors.systemRed
                                  : CupertinoColors.activeBlue, 
                              size: 28
                            ),
                          ),
                          onPressed: () {
                            if (provider.isRecording || provider.isPaused) {
                              _showDiscardConfirmDialog(context, provider);
                            } else {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => const RecordingsListScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: 200,
                          child: AnimatedBuilder(
                            animation: provider, 
                            builder: (context, child) {
                               return WaveformWidget(
                                 amplitudes: provider.amplitudeHistory,
                                 color: (provider.isRecording && !provider.isPaused) 
                                     ? CupertinoColors.systemRed 
                                     : CupertinoColors.white,
                               );
                            }
                          ),
                        ),
                        const SizedBox(height: 35),
                        if (provider.isRecording || provider.isPaused)
                          Text(
                            FormatUtils.formatDuration(Duration(milliseconds: provider.recordDurationMs), showMilliseconds: true),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1.0,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          )
                        else
                          const Text(
                            "00:00.00",
                            style: TextStyle(
                              color: CupertinoColors.systemGrey2,
                              fontSize: 48,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1.0,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Left: Empty space to keep Record button centered
                              const SizedBox(width: 80),
                              
                              // Center: Record/Stop Button
                              GestureDetector(
                                onTap: () {
                                  if (provider.isRecording && !provider.isPaused) {
                                    provider.pauseRecording();
                                  } else if (provider.isPaused) {
                                    provider.resumeRecording();
                                  } else {
                                    provider.startRecording();
                                  }
                                },
                                child: Container(
                                  height: 84,
                                  width: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: CupertinoColors.white.withValues(alpha: 0.4),
                                      width: 4,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       border: Border.all(
                                         color: CupertinoColors.black,
                                         width: 3,
                                       ),
                                     ),
                                     child: Center(
                                       child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                          height: (provider.isRecording && !provider.isPaused) ? 35 : 66,
                                          width: (provider.isRecording && !provider.isPaused) ? 35 : 66,
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemRed,
                                            borderRadius: (provider.isRecording && !provider.isPaused)
                                                ? BorderRadius.circular(8)
                                                : BorderRadius.circular(33),
                                            gradient: (provider.isRecording && !provider.isPaused) 
                                              ? null 
                                              : const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    CupertinoColors.systemRed,
                                                    Color(0xFFB71C1C), // Deep red shade
                                                  ],
                                                ),
                                          ),
                                           child: const SizedBox.shrink(),
                                       ),
                                     ),
                                  ),
                                ),
                              ),
                              
                              // Right: Done/Save (Only if recording/paused)
                              SizedBox(
                                width: 80,
                                child: (provider.isRecording || provider.isPaused)
                                  ? CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final path = await provider.stopRecording();
                                        if (path != null && context.mounted) {
                                          _showSaveDialog(context, provider, path);
                                        }
                                      },
                                      child: const Text(
                                        'Done',
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
    );
  }

  void _showDiscardConfirmDialog(BuildContext context, RecordProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text('This will permanently delete the current recording.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Recording',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.discardRecording();
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context, RecordProvider provider, String path) {
    final TextEditingController controller = TextEditingController(
      text: 'Recording_${FormatUtils.formatDate(DateTime.now()).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}'
    );

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Save Recording'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Recording Name',
              style: const TextStyle(color: CupertinoColors.white),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () {
                Navigator.pop(context); // Discard (file is just not added to list, maybe delete file from storage if needed)
                // Optionally delete the temp file
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Save',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  provider.saveRecording(path, controller.text.trim());
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
