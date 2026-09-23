import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_image_carousel.dart';

void main() {
  test('list-card hero tags differ by scope and index', () {
    const id = 'sku-1';
    expect(
      productCardHeroTag(id, scope: 'home-explore', index: 0),
      isNot(productCardHeroTag(id, scope: 'flash', index: 0)),
    );
    expect(
      productCardHeroTag(id, scope: 'home-explore', index: 0),
      isNot(productCardHeroTag(id, scope: 'home-explore', index: 1)),
    );
    expect(
      productCardHeroTag(id, scope: 'cart-suggest', index: 0),
      isNot(productHeroTag(id)),
    );
    expect(
      productCardHeroTag(id, scope: 'flash-home', index: 0),
      isNot(productCardHeroTag(id, scope: 'flash-explore', index: 0)),
    );
    expect(
      productCardHeroTag(id, scope: 'flash-home', index: 0),
      isNot(productCardHeroTag(id, scope: 'flash-offers', index: 0)),
    );
    expect(
      productCardHeroTag(id, scope: 'recs-home', index: 0),
      isNot(productCardHeroTag(id, scope: 'recs-explore', index: 0)),
    );
    expect(
      productCardHeroTag(id, scope: 'featured-Trending deals', index: 0),
      isNot(productCardHeroTag(id, scope: 'featured-Buy 1 Get 1', index: 0)),
    );
  });

  testWidgets('duplicate product ids can coexist with scoped hero tags',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Hero(
                tag: productCardHeroTag('p1', scope: 'home', index: 0),
                child: const SizedBox(width: 20, height: 20),
              ),
              Hero(
                tag: productCardHeroTag('p1', scope: 'flash', index: 0),
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  Future<void> pushRoute(WidgetTester tester) async {
    await tester.tap(find.text('push'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('same tag on two visible tabs throws during navigation',
      (tester) async {
    const tag = 'product-image-p1::flash::0';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: IndexedStack(
              index: 0,
              children: [
                Hero(tag: tag, child: const SizedBox(width: 20, height: 20)),
                Hero(tag: tag, child: const SizedBox(width: 20, height: 20)),
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
    );

    await pushRoute(tester);
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('multiple heroes that share the same tag'),
    );
    expect(error.toString(), contains(tag));
  });

  testWidgets('HeroMode drops the offstage duplicate and screen scopes do not collide',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: IndexedStack(
              index: 0,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: productCardHeroTag('p1', scope: 'flash-home', index: 0),
                      child: const SizedBox(width: 20, height: 20),
                    ),
                    Hero(
                      tag: productCardHeroTag(
                        'p1',
                        scope: 'featured-Trending deals',
                        index: 0,
                      ),
                      child: const SizedBox(width: 20, height: 20),
                    ),
                  ],
                ),
                HeroMode(
                  enabled: false,
                  child: Hero(
                    tag: productCardHeroTag('p1', scope: 'flash-home', index: 0),
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
                HeroMode(
                  enabled: false,
                  child: Hero(
                    tag: productCardHeroTag('p1', scope: 'flash-offers', index: 0),
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
              ],
            ),
            floatingActionButton: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Hero(
                        tag: productHeroTag('p1'),
                        child: const SizedBox(width: 40, height: 40),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('push'),
            ),
          ),
        ),
      ),
    );

    await pushRoute(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(Hero), findsWidgets);
  });

  testWidgets('two cart lines for one product id keep distinct hero tags',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Hero(
                  tag: 'cart-item-p1-line-0',
                  child: const SizedBox(width: 20, height: 20),
                ),
                Hero(
                  tag: 'cart-item-p1-combo-a-1',
                  child: const SizedBox(width: 20, height: 20),
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
    );

    await pushRoute(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product gallery infinite scroll does not clone the hero slide',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: SizedBox(
              height: 220,
              child: CarouselSlider.builder(
                itemCount: 3,
                itemBuilder: (_, index, __) => Hero(
                  tag: index == 0
                      ? productHeroTag('p1')
                      : 'gallery-slide-$index',
                  child: const SizedBox(width: 40, height: 40),
                ),
                options: CarouselOptions(
                  height: 220,
                  viewportFraction: 1,
                  enableInfiniteScroll: true,
                  autoPlay: false,
                ),
              ),
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
    );
    await tester.pump();

    await pushRoute(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error toast fits above a tall checkout dock', (tester) async {
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showTopErrorToast(context, 'Limit reached'),
                  child: const Text('toast'),
                ),
              ),
            ),
            bottomNavigationBar: const SizedBox(
              height: 140,
              child: ColoredBox(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('toast'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Limit reached'), findsOneWidget);
  });
}
