import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_golas/ui/core/theme/app_theme.dart';
import 'package:book_golas/ui/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    group('Light theme', () {
      test('returns valid ThemeData', () {
        final theme = AppTheme.light;
        expect(theme, isA<ThemeData>());
      });

      test('has light brightness', () {
        final theme = AppTheme.light;
        expect(theme.brightness, equals(Brightness.light));
      });

      test('uses Material 3', () {
        final theme = AppTheme.light;
        expect(theme.useMaterial3, isTrue);
      });

      test('has correct scaffold background color', () {
        final theme = AppTheme.light;
        expect(
          theme.scaffoldBackgroundColor,
          equals(AppColors.scaffoldLight),
        );
      });

      test('primary color is correctly set in colorScheme', () {
        final theme = AppTheme.light;
        expect(
          theme.colorScheme.primary,
          isNotNull,
        );
      });
    });

    group('Dark theme', () {
      test('returns valid ThemeData', () {
        final theme = AppTheme.dark;
        expect(theme, isA<ThemeData>());
      });

      test('has dark brightness', () {
        final theme = AppTheme.dark;
        expect(theme.brightness, equals(Brightness.dark));
      });

      test('uses Material 3', () {
        final theme = AppTheme.dark;
        expect(theme.useMaterial3, isTrue);
      });

      test('has correct scaffold background color', () {
        final theme = AppTheme.dark;
        expect(
          theme.scaffoldBackgroundColor,
          equals(AppColors.scaffoldDark),
        );
      });
    });

    group('Input decoration theme', () {
      test('light theme has filled input decoration', () {
        final theme = AppTheme.light;
        expect(theme.inputDecorationTheme.filled, isTrue);
      });

      test('dark theme has filled input decoration', () {
        final theme = AppTheme.dark;
        expect(theme.inputDecorationTheme.filled, isTrue);
      });
    });

    group('Button themes', () {
      test('light theme has elevated button theme', () {
        final theme = AppTheme.light;
        expect(theme.elevatedButtonTheme, isNotNull);
      });

      test('dark theme has elevated button theme', () {
        final theme = AppTheme.dark;
        expect(theme.elevatedButtonTheme, isNotNull);
      });
    });
  });
}
