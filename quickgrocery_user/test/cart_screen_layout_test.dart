import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_cart_item_card.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_checkout_bar.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_empty_cart.dart';

CartItem _item({
  required String id,
  required String name,
  int count = 1,
  double price = 45,
  double slashed = 54,
}) {
  return CartItem(
    productId: id,
    name: name,
    image: '',
    unit: 'pcs',
    unitPerItem: '1 kg',
    category: 'grocery',
    subcategory: 'staples',
    vendorId: 'v1',
    price: slashed,
    slashedPrice: price,
    stock: 20,
    maxOrder: 10,
    itemCount: count,
    selectedWeightInGrams: 1000,
    isVegetable: false,
  );
}

Widget _app({
  required Size size,
  required Widget body,
  Widget? bottom,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: body,
        bottomNavigationBar: bottom,
      ),
    ),
  );
}

void main() {
  testWidgets('checkout bar does not zero the scaffold body height',
      (tester) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        size: size,
        body: const ColoredBox(
          key: Key('cart-body'),
          color: Colors.yellow,
          child: Center(child: Text('CART_ITEM_VISIBLE')),
        ),
        bottom: PremiumCheckoutBar(
          total: 45,
          itemCount: 1,
          savings: 9,
          enabled: true,
          isLoading: false,
          onCheckout: () {},
        ),
      ),
    );

    expect(find.text('CART_ITEM_VISIBLE'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
    expect(find.text('1 item in cart'), findsOneWidget);
    expect(find.textContaining('Saved ₹9'), findsOneWidget);

    final bodySize = tester.getSize(find.byKey(const Key('cart-body')));
    expect(bodySize.height, greaterThan(size.height * 0.45));

    final barSize = tester.getSize(find.byType(PremiumCheckoutBar));
    expect(barSize.height, greaterThan(48));
    expect(barSize.height, lessThan(size.height * 0.45));
  });

  testWidgets('one cart item renders name, price and footer stays visible',
      (tester) async {
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        body: ListView(
          children: [
            PremiumCartItemCard(
              item: _item(id: 'p1', name: 'Tomato'),
              lineIndex: 0,
              onIncrement: () {},
              onDecrement: () {},
              onRemove: () {},
            ),
          ],
        ),
        bottom: PremiumCheckoutBar(
          total: 45,
          itemCount: 1,
          savings: 9,
          enabled: true,
          isLoading: false,
          onCheckout: () {},
        ),
      ),
    );

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.byType(PremiumCartItemCard), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
    expect(tester.getSize(find.byType(PremiumCartItemCard)).height, greaterThan(70));
  });

  testWidgets('multiple cart items render and can scroll', (tester) async {
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        body: ListView(
          children: [
            for (var i = 0; i < 5; i++)
              PremiumCartItemCard(
                item: _item(id: 'p$i', name: 'Item $i', count: 1),
                lineIndex: i,
                onIncrement: () {},
                onDecrement: () {},
                onRemove: () {},
              ),
          ],
        ),
        bottom: PremiumCheckoutBar(
          total: 225,
          itemCount: 5,
          savings: 45,
          enabled: true,
          isLoading: false,
          onCheckout: () {},
        ),
      ),
    );

    expect(find.byType(PremiumCartItemCard), findsWidgets);
    expect(find.text('Item 0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Item 4'), 200);
    expect(find.text('Item 4'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
  });

  testWidgets('empty cart body is visible above no footer', (tester) async {
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        body: PremiumEmptyCart(onBrowse: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('Cart Is Empty'), findsOneWidget);
  });

  testWidgets('quantity and remove callbacks fire', (tester) async {
    var inc = 0;
    var dec = 0;
    var removed = 0;
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        body: PremiumCartItemCard(
          item: _item(id: 'p1', name: 'Onion', count: 2),
          lineIndex: 0,
          onIncrement: () => inc++,
          onDecrement: () => dec++,
          onRemove: () => removed++,
        ),
        bottom: PremiumCheckoutBar(
          total: 90,
          itemCount: 2,
          savings: 18,
          enabled: true,
          isLoading: false,
          onCheckout: () {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();

    expect(inc, 1);
    expect(dec, 1);
    expect(removed, 1);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
  });

  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1024, 768),
  ]) {
    testWidgets('cart item + footer layout on ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          size: size,
          body: ListView(
            children: [
              PremiumCartItemCard(
                item: _item(id: 'p1', name: 'Milk 1L'),
                lineIndex: 0,
                onIncrement: () {},
                onDecrement: () {},
                onRemove: () {},
              ),
            ],
          ),
          bottom: PremiumCheckoutBar(
            total: 45,
            itemCount: 1,
            savings: 9,
            enabled: true,
            isLoading: false,
            onCheckout: () {},
          ),
        ),
      );

      expect(find.text('Milk 1L'), findsOneWidget);
      final itemH = tester.getSize(find.byType(PremiumCartItemCard)).height;
      final barH = tester.getSize(find.byType(PremiumCheckoutBar)).height;
      expect(itemH, greaterThan(70));
      expect(barH, lessThan(size.height * 0.45));
      expect(find.text('Proceed to Checkout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('two lines with the same product id do not share a hero tag',
      (tester) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: const MediaQueryData(size: size),
            child: Scaffold(
              body: ListView(
                children: [
                  PremiumCartItemCard(
                    item: _item(id: 'p1', name: 'Tomato'),
                    lineIndex: 0,
                    onIncrement: () {},
                    onDecrement: () {},
                    onRemove: () {},
                  ),
                  PremiumCartItemCard(
                    item: _item(id: 'p1', name: 'Tomato'),
                    lineIndex: 1,
                    onIncrement: () {},
                    onDecrement: () {},
                    onRemove: () {},
                  ),
                ],
              ),
              floatingActionButton: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: SizedBox.shrink()),
                    ),
                  );
                },
                child: const Text('push'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('push'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });
}
