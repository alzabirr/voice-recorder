import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/record_provider.dart';
import '../utils/format_utils.dart';
import 'playback_screen.dart';

class RecordingsListScreen extends StatelessWidget {
  const RecordingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Recordings',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 24,
              ),
            ),
            backgroundColor: const Color(0xCC000000), // Glassy background
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsetsDirectional.only(end: 16),
          ),
          SliverToBoxAdapter(
            child: Consumer<RecordProvider>(
              builder: (context, provider, child) {
                final recordings = provider.recordings;
                if (recordings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.only(top: 140),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.mic_fill,
                              size: 70,
                              color: CupertinoColors.systemGrey3,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'No Recordings',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your voice memos will appear here',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: recordings.map((recording) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CupertinoListSection.insetGrouped(
                          backgroundColor: CupertinoColors.transparent,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          children: [
                            Dismissible(
                              key: Key(recording.id),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.white, size: 24),
                              ),
                              secondaryBackground: Container(
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white, size: 24),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  provider.deleteRecording(recording.id);
                                  return true;
                                } else {
                                  _showRenameDialog(context, provider, recording.id, recording.name);
                                  return false;
                                }
                              },
                              child: CupertinoListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) => PlaybackScreen(recording: recording),
                                    ),
                                  );
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                leadingSize: 44,
                                leading: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF303030), Color(0xFF1C1C1E)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.black.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(CupertinoIcons.mic_fill, color: CupertinoColors.white, size: 22),
                                  ),
                                ),
                                title: Text(
                                  recording.name,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                subtitle: Text(
                                  FormatUtils.formatDate(recording.date),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      FormatUtils.formatDuration(recording.duration),
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.chevron_forward, 
                                      color: Color(0xFF3A3A3C), 
                                      size: 16
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    RecordProvider provider,
    String id,
    String currentName,
  ) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Rename Recording'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Recording Name',
              autofocus: true,
              style: const TextStyle(color: CupertinoColors.white),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Save',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  provider.renameRecording(id, controller.text.trim());
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
