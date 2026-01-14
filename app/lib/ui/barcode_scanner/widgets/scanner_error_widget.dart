import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerErrorWidget extends StatelessWidget {
  final MobileScannerException error;

  const ScannerErrorWidget({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = '카메라 권한이 필요합니다\n설정에서 권한을 허용해주세요';
        icon = Icons.no_photography_outlined;
        break;
      case MobileScannerErrorCode.controllerUninitialized:
        message = '카메라를 초기화하는 중입니다';
        icon = Icons.hourglass_empty;
        break;
      default:
        message = '카메라 오류가 발생했습니다\n다시 시도해주세요';
        icon = Icons.error_outline;
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    color: Color(0xFF5B7FFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
