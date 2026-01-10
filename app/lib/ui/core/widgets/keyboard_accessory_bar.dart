import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardAccessoryBar extends StatefulWidget {
  final VoidCallback onDone;
  final bool isDark;
  final IconData? icon;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool showNavigation;
  final bool canGoUp;
  final bool canGoDown;
  final bool canUndo;
  final bool canRedo;

  const KeyboardAccessoryBar({
    super.key,
    required this.onDone,
    required this.isDark,
    this.icon,
    this.onUp,
    this.onDown,
    this.onUndo,
    this.onRedo,
    this.showNavigation = false,
    this.canGoUp = true,
    this.canGoDown = true,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  State<KeyboardAccessoryBar> createState() => _KeyboardAccessoryBarState();
}

class _KeyboardAccessoryBarState extends State<KeyboardAccessoryBar> {
  Timer? _repeatTimer;
  static const _initialDelay = Duration(milliseconds: 500);
  static const _repeatInterval = Duration(milliseconds: 100);

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _startRepeat(VoidCallback action) {
    action();
    HapticFeedback.lightImpact();

    _repeatTimer = Timer(_initialDelay, () {
      _repeatTimer = Timer.periodic(_repeatInterval, (_) {
        action();
        HapticFeedback.selectionClick();
      });
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  Widget _buildIconButton({
    required VoidCallback? onTap,
    required IconData iconData,
    bool enabled = true,
    bool supportLongPress = false,
  }) {
    final effectiveAlpha = enabled ? 1.0 : 0.3;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      onLongPressStart: supportLongPress && enabled && onTap != null
          ? (_) => _startRepeat(onTap)
          : null,
      onLongPressEnd: supportLongPress && enabled ? (_) => _stopRepeat() : null,
      onLongPressCancel: supportLongPress && enabled ? _stopRepeat : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Icon(
          iconData,
          size: 20,
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.9 * effectiveAlpha)
              : Colors.black.withValues(alpha: 0.7 * effectiveAlpha),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: widget.isDark ? 0.15 : 0.6),
                  Colors.white.withValues(alpha: widget.isDark ? 0.08 : 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color:
                    Colors.white.withValues(alpha: widget.isDark ? 0.2 : 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.showNavigation) ...[
                  _buildIconButton(
                    onTap: widget.onUp,
                    iconData: CupertinoIcons.chevron_up,
                    enabled: widget.canGoUp && widget.onUp != null,
                  ),
                  _buildDivider(),
                  _buildIconButton(
                    onTap: widget.onDown,
                    iconData: CupertinoIcons.chevron_down,
                    enabled: widget.canGoDown && widget.onDown != null,
                  ),
                ],
                const Spacer(),
                if (widget.onUndo != null) ...[
                  _buildIconButton(
                    onTap: widget.onUndo,
                    iconData: CupertinoIcons.arrow_uturn_left,
                    enabled: widget.canUndo,
                    supportLongPress: true,
                  ),
                  _buildDivider(),
                ],
                if (widget.onRedo != null) ...[
                  _buildIconButton(
                    onTap: widget.onRedo,
                    iconData: CupertinoIcons.arrow_uturn_right,
                    enabled: widget.canRedo,
                    supportLongPress: true,
                  ),
                  _buildDivider(),
                ],
                _buildIconButton(
                  onTap: widget.onDone,
                  iconData: widget.icon ??
                      CupertinoIcons.keyboard_chevron_compact_down,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
