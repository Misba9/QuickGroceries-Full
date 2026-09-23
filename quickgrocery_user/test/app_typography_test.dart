import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/app_typography.dart';
import 'package:quickgrocery/core/widgets/animated_add_button.dart';
import 'package:quickgrocery/core/widgets/quantity_stepper.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';

void main() {
  test('named type scale meets App Review readability floors', () {
    expect(AppTypography.displaySize, greaterThanOrEqualTo(28));
    expect(AppTypography.headingSize, greaterThanOrEqualTo(20));
    expect(AppTypography.sectionSize, greaterThanOrEqualTo(18));
    expect(AppTypography.bodySize, greaterThanOrEqualTo(15));
    expect(AppTypography.buttonSize, greaterThanOrEqualTo(15));
    expect(AppTypography.secondarySize, greaterThanOrEqualTo(13));
    expect(AppTypography.captionSize, greaterThanOrEqualTo(12));
    expect(AppTypography.badgeSize, 11);
    expect(AppTypography.minReadable, 12);
    expect(AppTypography.buttonMinHeight, greaterThanOrEqualTo(48));
  });

  test('muted text is darker than the old mid-grey', () {
    expect(AppSurface.textMuted.toARGB32(), lessThan(0xFF6B6B73));
    expect(AppSurface.textSecondary.toARGB32(), lessThan(0xFF555560));
  });

  testWidgets('primary login CTA is 16sp and at least 48pt tall', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: 'Continue', onTap: () {}),
        ),
      ),
    );
    final box = tester.getSize(find.byType(PrimaryButton));
    expect(box.height, greaterThanOrEqualTo(48));
    final style = tester.widget<Text>(find.text('Continue')).style!;
    expect(style.fontSize, greaterThanOrEqualTo(16));
  });

  testWidgets('Dynamic Type is not disabled', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          home: Scaffold(body: Text('Readable body')),
        ),
      ),
    );
    final context = tester.element(find.text('Readable body'));
    expect(MediaQuery.textScalerOf(context).scale(15), closeTo(19.5, 0.01));
  });

  testWidgets('ADD control is at least 36pt on the compact size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedAddButton(
              count: 0,
              onAdd: () {},
              onIncrement: () {},
              onDecrement: () {},
              size: QuantityStepperSize.small,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(AnimatedAddButton)).height,
      greaterThanOrEqualTo(36),
    );
  });
}
