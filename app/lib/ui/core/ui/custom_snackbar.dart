import 'dart:ui';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, info, warning }

class CustomSnackbar {
  /// 스낵바 표시
  /// [bottomOffset] - CTA 버튼이 있는 화면에서는 100 (기본값), 없는 화면에서는 32 사용
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.success,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    bool rootOverlay = false,
    double bottomOffset = 100,
  }) {
    final overlay = Overlay.of(context, rootOverlay: rootOverlay);
    final overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedSnackbar(
        message: message,
        type: type,
        icon: icon,
        duration: duration,
        bottomOffset: bottomOffset,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration + const Duration(milliseconds: 400), () {
      overlayEntry.remove();
    });
  }
}

class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final IconData? icon;
  final Duration duration;
  final double bottomOffset;

  const _AnimatedSnackbar({
    required this.message,
    required this.type,
    this.icon,
    required this.duration,
    required this.bottomOffset,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    if (widget.icon != null) return widget.icon!;
    switch (widget.type) {
      case SnackbarType.success:
        return Icons.check_circle_outline_rounded;
      case SnackbarType.error:
        return Icons.error_outline_rounded;
      case SnackbarType.info:
        return Icons.info_outline_rounded;
      case SnackbarType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottomOffset,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.type == SnackbarType.error
                          ? Colors.red.withOpacity(0.7)
                          : Colors.white.withOpacity(0.2),
                      width: widget.type == SnackbarType.error ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getIcon(),
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
