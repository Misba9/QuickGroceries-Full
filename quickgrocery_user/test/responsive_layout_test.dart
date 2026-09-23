import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';

void main() {
  test('product grids stay 2 columns on phones', () {
    expect(Responsive.productGridColumnsForWidth(320), 2);
    expect(Responsive.productGridColumnsForWidth(390), 2);
    expect(Responsive.productGridColumnsForWidth(430), 2);
    expect(Responsive.productGridColumnsForWidth(599), 2);
  });

  test('product grids use 3 columns on small tablets / landscape phones', () {
    expect(Responsive.productGridColumnsForWidth(600), 3);
    expect(Responsive.productGridColumnsForWidth(768), 3);
    expect(Responsive.productGridColumnsForWidth(834), 3);
    expect(Responsive.productGridColumnsForWidth(899), 3);
  });

  test('product grids use 4 columns around 11-inch iPad landscape', () {
    expect(Responsive.productGridColumnsForWidth(900), 4);
    expect(Responsive.productGridColumnsForWidth(1024), 4);
    expect(Responsive.productGridColumnsForWidth(1180), 4);
  });

  test('product grids use 5 columns on very wide panes', () {
    expect(Responsive.productGridColumnsForWidth(1200), 5);
    expect(Responsive.productGridColumnsForWidth(1366), 5);
  });

  test('min card width caps columns so tiles are not too narrow', () {
    expect(
      Responsive.productGridColumnsForWidth(500),
      2,
    );
    final cols = Responsive.productGridColumnsForWidth(834);
    final tile =
        (834 - Responsive.productGridSpacing * (cols - 1)) / cols;
    expect(tile, greaterThanOrEqualTo(AppBreakpoints.productMinCardWidth - 1));
  });

  testWidgets('horizontal inset centers content on extra-wide iPads', (tester) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1366, 1024)),
        child: Builder(
          builder: (context) {
            inset = Responsive.of(context).horizontalInset();
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(inset, greaterThan(64));
    expect(1366 - inset * 2, closeTo(AppBreakpoints.contentMaxWidth, 1));
  });

  testWidgets('product aspect ratio shrinks (taller cells) at large text',
      (tester) async {
    late double normal;
    late double large;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1),
        ),
        child: Builder(
          builder: (context) {
            normal = Responsive.productCardAspectRatio(context, columns: 2);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.5),
        ),
        child: Builder(
          builder: (context) {
            large = Responsive.productCardAspectRatio(context, columns: 2);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(large, lessThan(normal));
  });
}
