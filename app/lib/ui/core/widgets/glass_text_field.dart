import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GlassTextFieldState {
  normal,
  focused,
  error,
  disabled,
  loading,
}

enum ErrorMessagePosition {
  below,
  inline,
  none,
}

class GlassTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool showPasswordToggle;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final bool? isDark;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final double borderRadius;

  final bool validateOnChange;
  final bool validateOnBlur;
  final String? externalError;
  final int validationDebounceMs;

  final ErrorMessagePosition errorMessagePosition;
  final bool showErrorIcon;
  final bool hapticFeedbackOnError;
  final bool shakeOnError;

  final bool isLoading;

  final void Function(String? error)? onErrorChanged;
  final void Function(bool isValid)? onValidityChanged;

  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.isDark,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.borderRadius = 14,
    this.validateOnChange = false,
    this.validateOnBlur = false,
    this.externalError,
    this.validationDebounceMs = 300,
    this.errorMessagePosition = ErrorMessagePosition.below,
    this.showErrorIcon = true,
    this.hapticFeedbackOnError = true,
    this.shakeOnError = false,
    this.isLoading = false,
    this.onErrorChanged,
    this.onValidityChanged,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  String? _errorMessage;
  bool _isDirty = false;
  bool _hasBlurred = false;
  Timer? _debounceTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  GlassTextFieldState get _currentState {
    if (!widget.enabled) return GlassTextFieldState.disabled;
    if (widget.isLoading) return GlassTextFieldState.loading;
    if (_shouldShowError) return GlassTextFieldState.error;
    if (_isFocused) return GlassTextFieldState.focused;
    return GlassTextFieldState.normal;
  }

  String? get _displayError => widget.externalError ?? _errorMessage;

  bool get _shouldShowError {
    if (_displayError == null) return false;
    if (widget.externalError != null) return true;
    if (widget.validateOnChange && _isDirty) return true;
    if (widget.validateOnBlur && _hasBlurred) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _focusNode.addListener(_handleFocusChange);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(GlassTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.externalError != oldWidget.externalError) {
      if (widget.externalError != null) {
        _triggerErrorFeedback();
      }
      widget.onErrorChanged?.call(widget.externalError);
      widget.onValidityChanged?.call(widget.externalError == null);
    }

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else {
        _controller = TextEditingController();
        _ownsController = true;
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
        _ownsFocusNode = false;
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      }
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _shakeController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;

    if (_isFocused != hasFocus) {
      setState(() => _isFocused = hasFocus);
    }

    if (!hasFocus && _isFocused == false && _isDirty) {
      _hasBlurred = true;
      if (widget.validateOnBlur) {
        _runValidation(_controller.text);
      }
    }
  }

  void _handleOnChanged(String value) {
    _isDirty = true;
    widget.onChanged?.call(value);

    if (widget.validateOnChange) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        Duration(milliseconds: widget.validationDebounceMs),
        () => _runValidation(value),
      );
    }
  }

  void _runValidation(String value) {
    if (widget.validator == null) return;

    final error = widget.validator!(value);
    final previousError = _errorMessage;

    setState(() {
      _errorMessage = error;
    });

    if (error != previousError) {
      if (error != null && previousError == null) {
        _triggerErrorFeedback();
      }
      widget.onErrorChanged?.call(error);
      widget.onValidityChanged?.call(error == null);
    }
  }

  void _triggerErrorFeedback() {
    if (widget.hapticFeedbackOnError) {
      HapticFeedback.mediumImpact();
    }
    if (widget.shakeOnError) {
      _shakeController.forward(from: 0);
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.isDark ?? Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          ),
          child: _GlassContainer(
            isDark: isDark,
            state: _currentState,
            borderRadius: widget.borderRadius,
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: _obscureText,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              autofillHints: widget.autofillHints,
              enabled: widget.enabled && !widget.isLoading,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              onFieldSubmitted: widget.onFieldSubmitted,
              onChanged: _handleOnChanged,
              style: TextStyle(
                fontSize: 15,
                color: widget.enabled
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _currentState == GlassTextFieldState.error
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        size: 20,
                      )
                    : null,
                suffixIcon: _buildSuffixIcon(isDark),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
        _buildErrorMessage(isDark),
      ],
    );
  }

  Widget _buildErrorMessage(bool isDark) {
    if (!_shouldShowError ||
        widget.errorMessagePosition != ErrorMessagePosition.below) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showErrorIcon)
              const Padding(
                padding: EdgeInsets.only(right: 4, top: 1),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
            Expanded(
              child: Text(
                _displayError!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isDark) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
        ),
      );
    }

    if (_shouldShowError &&
        widget.errorMessagePosition == ErrorMessagePosition.inline) {
      return const Icon(
        Icons.error_outline_rounded,
        color: Color(0xFFEF4444),
        size: 20,
      );
    }

    if (widget.showPasswordToggle && widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 20,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }

    return widget.suffixIcon;
  }
}

class _GlassContainer extends StatelessWidget {
  final bool isDark;
  final GlassTextFieldState state;
  final double borderRadius;
  final Widget child;

  const _GlassContainer({
    required this.isDark,
    required this.state,
    required this.borderRadius,
    required this.child,
  });

  Color _getBorderColor() {
    switch (state) {
      case GlassTextFieldState.error:
        return const Color(0xFFEF4444).withValues(alpha: 0.8);
      case GlassTextFieldState.focused:
        return isDark
            ? Colors.white.withValues(alpha: 0.30)
            : const Color(0xFF5B7FFF).withValues(alpha: 0.5);
      case GlassTextFieldState.disabled:
        return Colors.grey.withValues(alpha: 0.1);
      case GlassTextFieldState.loading:
      case GlassTextFieldState.normal:
        return isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.15);
    }
  }

  double _getBorderWidth() {
    return (state == GlassTextFieldState.focused ||
            state == GlassTextFieldState.error)
        ? 1.5
        : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isFocusedOrError = state == GlassTextFieldState.focused ||
        state == GlassTextFieldState.error;
    final borderWidth = _getBorderWidth();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: _getBorderColor(),
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white
                            .withValues(alpha: isFocusedOrError ? 0.20 : 0.08),
                        Colors.white
                            .withValues(alpha: isFocusedOrError ? 0.12 : 0.04),
                      ]
                    : [
                        Colors.white
                            .withValues(alpha: isFocusedOrError ? 1.0 : 0.85),
                        Colors.white
                            .withValues(alpha: isFocusedOrError ? 0.95 : 0.65),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
