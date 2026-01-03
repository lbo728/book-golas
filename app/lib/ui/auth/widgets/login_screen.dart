import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:book_golas/ui/core/widgets/custom_snackbar.dart';
import 'package:book_golas/ui/core/widgets/glass_text_field.dart';
import 'package:book_golas/ui/core/widgets/keyboard_accessory_bar.dart';

enum AuthMode { signIn, signUp, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nicknameFocusNode = FocusNode();
  final _emailFieldKey = GlobalKey();
  final _passwordFieldKey = GlobalKey();
  final _nicknameFieldKey = GlobalKey();

  AuthMode _authMode = AuthMode.signIn;
  bool _isLoading = false;
  bool _saveEmail = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _emailFocusNode.addListener(() => _onFocusChange(_emailFieldKey));
    _passwordFocusNode.addListener(() => _onFocusChange(_passwordFieldKey));
    _nicknameFocusNode.addListener(() => _onFocusChange(_nicknameFieldKey));
  }

  void _onFocusChange(GlobalKey fieldKey) {
    final hasFocus = _emailFocusNode.hasFocus ||
        _passwordFocusNode.hasFocus ||
        _nicknameFocusNode.hasFocus;
    if (_isKeyboardVisible != hasFocus) {
      setState(() => _isKeyboardVisible = hasFocus);
    }
    if (hasFocus) {
      _scrollToField(fieldKey);
    }
  }

  void _scrollToField(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = fieldKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.3,
        );
      }
    });
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final shouldSave = prefs.getBool('save_email') ?? false;
    if (savedEmail != null && shouldSave) {
      setState(() {
        _emailController.text = savedEmail;
        _saveEmail = true;
      });
    }
  }

  Future<void> _saveEmailPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (_saveEmail) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('save_email', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('save_email', false);
    }
  }

  void _dismissKeyboard() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    _nicknameFocusNode.unfocus();
  }

  void _focusNextField() {
    if (_emailFocusNode.hasFocus) {
      _passwordFocusNode.requestFocus();
    } else if (_passwordFocusNode.hasFocus) {
      if (_authMode == AuthMode.signUp) {
        _nicknameFocusNode.requestFocus();
      } else {
        _dismissKeyboard();
      }
    } else if (_nicknameFocusNode.hasFocus) {
      _dismissKeyboard();
    }
  }

  void _focusPreviousField() {
    if (_nicknameFocusNode.hasFocus) {
      _passwordFocusNode.requestFocus();
    } else if (_passwordFocusNode.hasFocus) {
      _emailFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      switch (_authMode) {
        case AuthMode.signIn:
          await _saveEmailPreference();
          await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          break;

        case AuthMode.signUp:
          final nickname = _nicknameController.text.trim();
          await supabase.auth.signUp(
            email: email,
            password: password,
            data: {'nickname': nickname},
          );
          if (mounted) {
            CustomSnackbar.show(
              context,
              message: '회원가입이 완료되었습니다. 이메일을 확인해주세요.',
              type: SnackbarType.success,
              bottomOffset: 32,
            );
            setState(() => _authMode = AuthMode.signIn);
          }
          break;

        case AuthMode.forgotPassword:
          await supabase.auth.resetPasswordForEmail(email);
          if (mounted) {
            CustomSnackbar.show(
              context,
              message: '비밀번호 재설정 이메일을 보냈습니다.',
              type: SnackbarType.success,
              bottomOffset: 32,
            );
            setState(() => _authMode = AuthMode.signIn);
          }
          break;
      }
    } on AuthException catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: _getAuthErrorMessage(e.message),
          type: SnackbarType.error,
          bottomOffset: 32,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: '예상치 못한 오류가 발생했습니다.',
          type: SnackbarType.error,
          bottomOffset: 32,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } else if (message.contains('Email not confirmed')) {
      return '이메일 인증이 완료되지 않았습니다.';
    } else if (message.contains('User already registered')) {
      return '이미 등록된 이메일입니다.';
    } else if (message.contains('Password should be at least')) {
      return '비밀번호는 6자 이상이어야 합니다.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    constraints.maxWidth > 500 ? 400.0 : double.infinity;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: keyboardHeight + 80,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          _buildLogoSection(isDark),
                          const SizedBox(height: 48),
                          _buildAuthCard(context, isDark),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isKeyboardVisible && keyboardHeight > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: KeyboardAccessoryBar(
                  isDark: isDark,
                  showNavigation: true,
                  onDone: _dismissKeyboard,
                  onUp: _focusPreviousField,
                  onDown: _focusNextField,
                  canGoUp: !_emailFocusNode.hasFocus,
                  canGoDown: _authMode == AuthMode.signUp
                      ? !_nicknameFocusNode.hasFocus
                      : _authMode == AuthMode.forgotPassword
                          ? false
                          : !_passwordFocusNode.hasFocus,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '북골라스',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getDescriptionText(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _getDescriptionText() {
    switch (_authMode) {
      case AuthMode.signIn:
        return '오늘도 한 페이지,\n당신의 독서를 응원합니다';
      case AuthMode.signUp:
        return '북골라스와 함께\n독서 습관을 시작해보세요';
      case AuthMode.forgotPassword:
        return '가입하신 이메일로\n재설정 링크를 보내드립니다';
    }
  }

  Widget _buildAuthCard(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.06),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassTextField(
                    key: _emailFieldKey,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: '이메일',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    isDark: isDark,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _focusNextField(),
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 주소를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  if (_authMode != AuthMode.forgotPassword) ...[
                    const SizedBox(height: 16),
                    GlassTextField(
                      key: _passwordFieldKey,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      label: '비밀번호',
                      hint: '6자 이상 입력해주세요',
                      obscureText: true,
                      showPasswordToggle: true,
                      prefixIcon: Icons.lock_outline,
                      isDark: isDark,
                      textInputAction: _authMode == AuthMode.signUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) => _focusNextField(),
                      autofillHints: _authMode == AuthMode.signIn
                          ? const [AutofillHints.password]
                          : const [AutofillHints.newPassword],
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_authMode == AuthMode.signUp) ...[
                    const SizedBox(height: 16),
                    GlassTextField(
                      key: _nicknameFieldKey,
                      controller: _nicknameController,
                      focusNode: _nicknameFocusNode,
                      label: '닉네임',
                      hint: '앱에서 사용할 이름',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _dismissKeyboard(),
                      isDark: isDark,
                      autofillHints: const [AutofillHints.nickname],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_authMode == AuthMode.signIn) ...[
                    const SizedBox(height: 12),
                    _buildSaveEmailCheckbox(isDark),
                  ],
                  const SizedBox(height: 24),
                  _buildGlassButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    isDark: isDark,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.white : Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _getButtonText(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (_authMode == AuthMode.signIn) ...[
                    _buildTextButton(
                      '비밀번호를 잊으셨나요?',
                      () => setState(() => _authMode = AuthMode.forgotPassword),
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildDivider(isDark),
                    const SizedBox(height: 8),
                    _buildTextButton(
                      '계정이 없으신가요? 회원가입',
                      () => setState(() => _authMode = AuthMode.signUp),
                      isDark,
                    ),
                  ] else if (_authMode == AuthMode.signUp) ...[
                    _buildTextButton(
                      '이미 계정이 있으신가요? 로그인',
                      () => setState(() => _authMode = AuthMode.signIn),
                      isDark,
                    ),
                  ] else ...[
                    _buildTextButton(
                      '로그인으로 돌아가기',
                      () => setState(() => _authMode = AuthMode.signIn),
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveEmailCheckbox(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _saveEmail = !_saveEmail),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _saveEmail
                    ? const Color(0xFF5B7FFF)
                    : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                width: 1.5,
              ),
              color: _saveEmail
                  ? const Color(0xFF5B7FFF)
                  : Colors.transparent,
            ),
            child: _saveEmail
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            '이메일 저장',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required bool isDark,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B8AFF),
                Color(0xFF5B7FFF),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7FFF).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed, bool isDark) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5B7FFF),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[300] : const Color(0xFF5B7FFF),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    switch (_authMode) {
      case AuthMode.signIn:
        return '로그인';
      case AuthMode.signUp:
        return '회원가입';
      case AuthMode.forgotPassword:
        return '비밀번호 재설정 이메일 보내기';
    }
  }
}
