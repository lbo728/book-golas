import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SupaEmailAuth(
              redirectTo: kIsWeb ? null : 'litgoal://login-callback',
              onSignInComplete: (_) {},
              onSignUpComplete: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('회원가입이 완료되었습니다. 이메일을 확인해주세요.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
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
          ],
        ),
      ),
    );
  }
}
