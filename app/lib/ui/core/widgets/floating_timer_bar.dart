import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/ui/book_detail/view_model/reading_timer_view_model.dart';
import 'package:book_golas/ui/core/theme/design_system.dart';

/// Floating timer bar that appears at bottom of screen when timer is running
class FloatingTimerBar extends StatelessWidget {
  final bool hasBottomNav;

  const FloatingTimerBar({
    super.key,
    this.hasBottomNav = true,
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

    return Consumer<ReadingTimerViewModel>(
      builder: (context, timerVm, child) {
        // Only show when timer is running or paused
        if (!timerVm.isRunning && !timerVm.isPaused) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: 16,
          right: 16,
          bottom:
              hasBottomNav ? 90 : 16, // Above bottom nav or 16px from bottom
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[900]!.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Pause/Resume button
                    _buildControlButton(
                      isDark: isDark,
                      icon: timerVm.isRunning
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      onTap: () {
                        if (timerVm.isRunning) {
                          timerVm.pause();
                        } else {
                          timerVm.resume();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    // Stop button
                    _buildControlButton(
                      isDark: isDark,
                      icon: CupertinoIcons.stop_fill,
                      onTap: () async {
                        await timerVm.stop();
                      },
                      isDestructive: true,
                    ),
                    const SizedBox(width: 16),
                    // Timer display
                    Expanded(
                      child: Text(
                        _formatDuration(timerVm.elapsed),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildControlButton({
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.destructive.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.destructive : AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}
