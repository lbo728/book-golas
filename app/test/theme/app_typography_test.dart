import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_golas/ui/core/theme/app_typography.dart';

void main() {
  group('AppTypography', () {
    group('Headlines', () {
      test('headline1 has fontSize 48', () {
        expect(AppTypography.headline1.fontSize, equals(48));
      });

      test('headline1 has fontWeight w700', () {
        expect(AppTypography.headline1.fontWeight, equals(FontWeight.w700));
      });

      test('headline2 has fontSize 32', () {
        expect(AppTypography.headline2.fontSize, equals(32));
      });

      test('headline2 has fontWeight w700', () {
        expect(AppTypography.headline2.fontWeight, equals(FontWeight.w700));
      });
    });

    group('Body', () {
      test('bodyMedium has fontSize 15', () {
        expect(AppTypography.bodyMedium.fontSize, equals(15));
      });

      test('bodyMedium has fontWeight w400', () {
        expect(AppTypography.bodyMedium.fontWeight, equals(FontWeight.w400));
      });

      test('bodyLarge has fontSize 16', () {
        expect(AppTypography.bodyLarge.fontSize, equals(16));
      });

      test('bodySmall has fontSize 14', () {
        expect(AppTypography.bodySmall.fontSize, equals(14));
      });
    });

    group('Labels', () {
      test('labelSmall has fontSize 12', () {
        expect(AppTypography.labelSmall.fontSize, equals(12));
      });

      test('labelSmall has fontWeight w500', () {
        expect(AppTypography.labelSmall.fontWeight, equals(FontWeight.w500));
      });

      test('labelMedium has fontSize 13', () {
        expect(AppTypography.labelMedium.fontSize, equals(13));
      });

      test('labelLarge has fontSize 14', () {
        expect(AppTypography.labelLarge.fontSize, equals(14));
      });
    });

    group('Titles', () {
      test('titleLarge has fontSize 18', () {
        expect(AppTypography.titleLarge.fontSize, equals(18));
      });

      test('titleLarge has fontWeight w600', () {
        expect(AppTypography.titleLarge.fontWeight, equals(FontWeight.w600));
      });
    });

    group('Buttons', () {
      test('buttonLarge has fontSize 16', () {
        expect(AppTypography.buttonLarge.fontSize, equals(16));
      });

      test('buttonLarge has fontWeight w600', () {
        expect(AppTypography.buttonLarge.fontWeight, equals(FontWeight.w600));
      });
    });

    group('Captions', () {
      test('captionSmall has fontSize 10', () {
        expect(AppTypography.captionSmall.fontSize, equals(10));
      });

      test('captionSmall has fontWeight w400', () {
        expect(AppTypography.captionSmall.fontWeight, equals(FontWeight.w400));
      });
    });
  });
}
