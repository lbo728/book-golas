import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_golas/ui/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Primary colors', () {
      test('primary equals Color(0xFF5B7FFF)', () {
        expect(AppColors.primary, equals(const Color(0xFF5B7FFF)));
      });
    });

    group('Semantic colors', () {
      test('success equals Color(0xFF10B981)', () {
        expect(AppColors.success, equals(const Color(0xFF10B981)));
      });

      test('error equals Color(0xFFFF3B30)', () {
        expect(AppColors.error, equals(const Color(0xFFFF3B30)));
      });

      test('warning equals Color(0xFFFF9500)', () {
        expect(AppColors.warning, equals(const Color(0xFFFF9500)));
      });
    });

    group('Chart colors', () {
      test('has 10 chart colors', () {
        expect(AppColors.chartColors.length, equals(10));
      });

      test('first chart color is primary', () {
        expect(AppColors.chartColors[0], equals(const Color(0xFF5B7FFF)));
      });
    });

    group('Light/Dark mode getters', () {
      testWidgets('scaffold returns correct color for light mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Builder(
              builder: (context) {
                expect(
                  AppColors.scaffold(context),
                  equals(AppColors.scaffoldLight),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('scaffold returns correct color for dark mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Builder(
              builder: (context) {
                expect(
                  AppColors.scaffold(context),
                  equals(AppColors.scaffoldDark),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('surface returns correct color for light mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Builder(
              builder: (context) {
                expect(
                  AppColors.surface(context),
                  equals(AppColors.surfaceLight),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('textPrimary returns correct color for light mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Builder(
              builder: (context) {
                expect(
                  AppColors.textPrimary(context),
                  equals(AppColors.textPrimaryLight),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('textPrimary returns correct color for dark mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Builder(
              builder: (context) {
                expect(
                  AppColors.textPrimary(context),
                  equals(AppColors.textPrimaryDark),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });
}
