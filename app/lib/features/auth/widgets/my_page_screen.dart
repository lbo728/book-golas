import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:book_golas/core/view_model/auth_view_model.dart';
import 'package:book_golas/core/view_model/notification_settings_view_model.dart';
import 'package:book_golas/data/services/fcm_service.dart';
import 'package:book_golas/data/services/notification_settings_service.dart';
import 'package:book_golas/core/view_model/theme_view_model.dart';
import 'package:book_golas/features/auth/view_model/my_page_view_model.dart';
import 'login_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyPageViewModel(),
      child: const _MyPageContent(),
    );
  }
}

class _MyPageContent extends StatefulWidget {
  const _MyPageContent();

  @override
  State<_MyPageContent> createState() => _MyPageContentState();
}

class _MyPageContentState extends State<_MyPageContent> {
  late TextEditingController _nicknameController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthViewModel>().fetchCurrentUser();
      context.read<NotificationSettingsViewModel>().loadSettings();
    });
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: const Text(
            '정말로 계정을 삭제하시겠습니까?\n\n'
            '이 작업은 되돌릴 수 없으며, 모든 데이터가 영구적으로 삭제됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.deleteAccount();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 성공적으로 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정 삭제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<int?> _showHourPicker({
    required BuildContext context,
    required int initialHour,
  }) async {
    final hours = NotificationSettingsService.getAvailableHours();
    int selectedIndex = initialHour;

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const Text(
                      '알림 시간 설정',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(context).pop(selectedIndex);
                      },
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialHour,
                  ),
                  itemExtent: 44,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: hours.map((hourData) {
                    return Center(
                      child: Text(
                        hourData['label'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationSettings() {
    return Consumer<NotificationSettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        final settings = settingsViewModel.settings;
        final isLoading = settingsViewModel.isLoading;

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('매일 독서 목표 알림'),
              subtitle: Text(
                settings.notificationEnabled
                    ? '매일 ${settingsViewModel.getFormattedTime()}에 알림을 받습니다'
                    : '알림을 받지 않습니다',
              ),
              trailing: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: settings.notificationEnabled,
                      onChanged: (value) async {
                        final success =
                            await settingsViewModel.updateNotificationEnabled(value);

                        if (success) {
                          if (value) {
                            await FCMService().scheduleDailyNotification(
                              hour: settings.preferredHour,
                              minute: 0,
                            );
                          } else {
                            await FCMService().cancelDailyNotification();
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value ? '알림이 활성화되었습니다' : '알림이 비활성화되었습니다',
                                ),
                                backgroundColor: value ? Colors.green : null,
                              ),
                            );
                          }
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                settingsViewModel.errorMessage ?? '알림 설정 변경에 실패했습니다',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
            ),
            if (settings.notificationEnabled)
              ListTile(
                leading: const SizedBox(width: 24),
                title: const Text('알림 시간'),
                trailing: TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final selectedHour = await _showHourPicker(
                            context: context,
                            initialHour: settings.preferredHour,
                          );

                          if (selectedHour != null) {
                            final success =
                                await settingsViewModel.updatePreferredHour(selectedHour);

                            if (success) {
                              await FCMService().scheduleDailyNotification(
                                hour: selectedHour,
                                minute: 0,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '알림 시간이 ${settingsViewModel.getFormattedTime()}으로 변경되었습니다',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    settingsViewModel.errorMessage ?? '알림 시간 변경에 실패했습니다',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(
                    settingsViewModel.getFormattedTime(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Consumer<MyPageViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('마이페이지'),
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await authViewModel.fetchCurrentUser();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user != null) ...[
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: vm.pendingAvatarFile != null
                                  ? null
                                  : () async {
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(
                                          source: ImageSource.gallery);
                                      if (picked != null) {
                                        vm.setPendingAvatarFile(
                                            File(picked.path));
                                      }
                                    },
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: ClipOval(
                                  child: vm.pendingAvatarFile != null
                                      ? Image.file(
                                          vm.pendingAvatarFile!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : (user.avatarUrl != null &&
                                              user.avatarUrl!.isNotEmpty)
                                          ? Image.network(
                                              user.avatarUrl!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    color: Colors.lightBlue[100],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: Colors.blue,
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.lightBlue[100],
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                size: 40,
                                                color: Colors.blue,
                                              ),
                                            ),
                                ),
                              ),
                            ),
                            if (vm.pendingAvatarFile != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (vm.pendingAvatarFile != null) {
                                        await authViewModel
                                            .uploadAvatar(vm.pendingAvatarFile!);
                                        vm.clearPendingAvatarFile();
                                      }
                                    },
                                    child: const Text('변경'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      vm.clearPendingAvatarFile();
                                    },
                                    child: const Text('취소'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      vm.isEditingNickname
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nicknameController,
                                    decoration: const InputDecoration(
                                      labelText: '닉네임',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await authViewModel
                                        .updateNickname(_nicknameController.text);
                                    vm.finishEditingNickname();
                                  },
                                  child: const Text('변경하기'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    vm.cancelEditingNickname();
                                    _nicknameController.text = user.nickname ?? '';
                                  },
                                  child: const Text('취소'),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.nickname ?? '닉네임 없음',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    vm.startEditingNickname();
                                    _nicknameController.text = user.nickname ?? '';
                                  },
                                  child: const Text('닉네임 변경'),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      Text('이메일: ${user.email}'),
                      const SizedBox(height: 32),
                    ],
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<ThemeViewModel>(
                      builder: (context, themeViewModel, child) {
                        return ListTile(
                          leading: Icon(
                            themeViewModel.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: const Text('다크 모드'),
                          trailing: Switch(
                            value: themeViewModel.isDarkMode,
                            onChanged: (value) {
                              themeViewModel.toggleTheme();
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildNotificationSettings(),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FCMService().scheduleTestNotification(seconds: 30);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('30초 후에 테스트 알림이 발송됩니다! 📱'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('테스트 알림 (30초 후)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await context.read<AuthViewModel>().signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('로그아웃'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => _showDeleteAccountDialog(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('계정 삭제'),
                          ),
                        ],
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
}
