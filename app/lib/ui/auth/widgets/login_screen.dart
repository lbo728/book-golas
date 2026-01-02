import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth > 500 ? 400.0 : double.infinity;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          '오늘도 한 페이지,\n당신의 독서를 응원합니다',
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

  Widget _buildAuthCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SupaEmailAuth(
          redirectTo: kIsWeb ? null : 'litgoal://login-callback',
          onSignInComplete: (_) {},
          onSignUpComplete: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('회원가입이 완료되었습니다. 이메일을 확인해주세요.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          },
          localization: const SupaEmailAuthLocalization(
            enterEmail: '이메일을 입력해주세요',
            validEmailError: '올바른 이메일 주소를 입력해주세요',
            enterPassword: '비밀번호를 입력해주세요',
            passwordLengthError: '비밀번호는 6자 이상이어야 합니다',
            signIn: '로그인',
            signUp: '회원가입',
            forgotPassword: '비밀번호를 잊으셨나요?',
            dontHaveAccount: '계정이 없으신가요? 회원가입',
            haveAccount: '이미 계정이 있으신가요? 로그인',
            sendPasswordReset: '비밀번호 재설정 이메일 보내기',
            backToSignIn: '로그인으로 돌아가기',
            unexpectedError: '예상치 못한 오류가 발생했습니다',
          ),
          metadataFields: [
            MetaDataField(
              prefixIcon: const Icon(Icons.person),
              label: '이름',
              key: 'name',
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return '이름을 입력해주세요.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
