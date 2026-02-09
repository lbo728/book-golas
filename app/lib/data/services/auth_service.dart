import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:book_golas/domain/models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  AuthService() {
    _init();
  }

  void _init() {
    _currentUser = _supabase.auth.currentUser != null
        ? UserModel.fromUser(_supabase.auth.currentUser!)
        : null;
  }

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      final userId = response.user?.id;
      if (userId != null) {
        await _supabase.from('users').insert({
          'id': userId,
          'email': email,
          'nickname': name,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<String?> signInWithKakao() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kIsWeb ? null : 'io.supabase.lit_goal://login-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.lit_goal://login-callback',
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<String?> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.lit_goal://reset-callback',
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<String?> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  Future<UserModel?> fetchCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data =
        await _supabase.from('users').select().eq('id', userId).maybeSingle();

    if (data == null) {
      final email = _supabase.auth.currentUser?.email ?? '';
      final nickname = email.split('@').first;

      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'nickname': nickname,
      });

      final newData =
          await _supabase.from('users').select().eq('id', userId).single();
      _currentUser = UserModel.fromJson(newData);
    } else {
      _currentUser = UserModel.fromJson(data);
    }

    return _currentUser;
  }

  Future<void> updateNickname(String nickname) async {
    final userId = _currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('users')
        .update({'nickname': nickname}).eq('id', userId);
    await fetchCurrentUser();
  }

  Future<void> uploadAvatar(File file) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final filePath = '$userId/avatar.png';
    debugPrint('🖼️ [Avatar] Uploading to: $filePath');

    await _supabase.storage.from('avatars').upload(
          filePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    debugPrint('🖼️ [Avatar] Upload complete');

    final baseUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
    final urlWithBust = '$baseUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('🖼️ [Avatar] URL: $urlWithBust');

    await _supabase
        .from('users')
        .update({'avatar_url': urlWithBust}).eq('id', userId);
    debugPrint('🖼️ [Avatar] Updated users table');

    await _supabase.auth.updateUser(
      UserAttributes(data: {'avatar_url': urlWithBust}),
    );
    debugPrint('🖼️ [Avatar] Updated auth metadata');

    await fetchCurrentUser();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = await _supabase.auth.getUser();
    _currentUser = UserModel.fromUser(user.user!);
    return _currentUser;
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _supabase.functions.invoke('delete-user');
      if (response.status == 200) {
        _currentUser = null;
        await _supabase.auth.signOut();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('계정 삭제 오류: $e');
      return false;
    }
  }
}
