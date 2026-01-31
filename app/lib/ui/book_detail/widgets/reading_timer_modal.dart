import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';
import 'package:book_golas/ui/core/widgets/liquid_glass_button.dart';

Future<void> showReadingTimerModal({
  required BuildContext context,
  required String bookId,
  required String bookTitle,
  VoidCallback? onTimerStopped,
}) async {
  final viewModel = context.read<ReadingTimerViewModel>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _ReadingTimerModalContent(
        bookId: bookId,
        bookTitle: bookTitle,
        viewModel: viewModel,
        onTimerStopped: onTimerStopped,
      );
    },
  );
}

class _ReadingTimerModalContent extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final ReadingTimerViewModel viewModel;
  final VoidCallback? onTimerStopped;

  const _ReadingTimerModalContent({
    required this.bookId,
    required this.bookTitle,
    required this.viewModel,
    this.onTimerStopped,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.timer,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            bookTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) {
              return Column(
                children: [
                  Text(
                    _formatDuration(viewModel.elapsed),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (!viewModel.isRunning && !viewModel.isPaused)
                        Expanded(
                          child: LiquidGlassButton(
                            text: '시작',
                            icon: CupertinoIcons.play_fill,
                            variant: LiquidGlassButtonVariant.primary,
                            isFullWidth: true,
                            onPressed: () {
                              viewModel.start(bookId);
                            },
                          ),
                        ),
                      if (viewModel.isRunning) ...[
                        Expanded(
                          child: LiquidGlassButton(
                            text: '일시정지',
                            icon: CupertinoIcons.pause_fill,
                            variant: LiquidGlassButtonVariant.secondary,
                            isFullWidth: true,
                            onPressed: () {
                              viewModel.pause();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LiquidGlassButton(
                            text: '종료',
                            icon: CupertinoIcons.stop_fill,
                            variant: LiquidGlassButtonVariant.destructive,
                            isFullWidth: true,
                            onPressed: () async {
                              await viewModel.stop();
                              if (context.mounted) {
                                Navigator.pop(context);
                                onTimerStopped?.call();
                              }
                            },
                          ),
                        ),
                      ],
                      if (viewModel.isPaused) ...[
                        Expanded(
                          child: LiquidGlassButton(
                            text: '재개',
                            icon: CupertinoIcons.play_fill,
                            variant: LiquidGlassButtonVariant.primary,
                            isFullWidth: true,
                            onPressed: () {
                              viewModel.resume();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LiquidGlassButton(
                            text: '종료',
                            icon: CupertinoIcons.stop_fill,
                            variant: LiquidGlassButtonVariant.destructive,
                            isFullWidth: true,
                            onPressed: () async {
                              await viewModel.stop();
                              if (context.mounted) {
                                Navigator.pop(context);
                                onTimerStopped?.call();
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
