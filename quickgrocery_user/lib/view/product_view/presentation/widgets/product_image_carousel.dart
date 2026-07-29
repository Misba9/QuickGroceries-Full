import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_branded_placeholder.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_display_image.dart';
import 'package:video_player/video_player.dart';

/// Hero tag for product image flights.
///
/// Always pass a unique [scope] when placing Heroes in list/grid rails —
/// the same [productId] often appears in multiple sections and in multiple
/// [IndexedStack] tabs at once. Duplicate tags cause:
/// `There are multiple heroes that share the same tag` →
/// `_dependents.isEmpty`.
String productHeroTag(String productId, {String? scope}) =>
    scope == null || scope.isEmpty
        ? 'product-image-$productId'
        : 'product-image-$productId::$scope';

/// Premium product gallery: large hero (~68% screen width), thumbnails, zoom.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({
    super.key,
    required this.product,
    this.heroTag,
  });
  final ProductModel product;

  /// When null, no [Hero] is used (avoids unpaired / colliding flights).
  final String? heroTag;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _index = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};

  late List<String> _images;
  late List<String> _videos;

  @override
  void initState() {
    super.initState();
    _hydrateMedia();
    _initVideos();
  }

  @override
  void didUpdateWidget(covariant ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.image != widget.product.image ||
        !_listEquals(oldWidget.product.images, widget.product.images) ||
        !_listEquals(oldWidget.product.videos, widget.product.videos)) {
      _disposeVideos();
      _hydrateMedia();
      _initVideos();
      _index = 0;
    }
  }

  void _hydrateMedia() {
    final images = <String>[];
    if (widget.product.images.isNotEmpty) {
      images.addAll(widget.product.images.map((e) => e.toString()));
    }
    if (widget.product.image.isNotEmpty &&
        !images.contains(widget.product.image)) {
      images.insert(0, widget.product.image);
    }
    _images = images;
    _videos = widget.product.videos.map((e) => e.toString()).toList();
  }

  void _initVideos() {
    final imageCount = _images.length;
    for (var i = 0; i < _videos.length; i++) {
      final idx = imageCount + i;
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_videos[i]),
      );
      _videoControllers[idx] = controller;
      controller.initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
  }

  void _disposeVideos() {
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    _videoControllers.clear();
  }

  @override
  void dispose() {
    _disposeVideos();
    super.dispose();
  }

  double _heroHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.68).clamp(280.0, 420.0);
  }

  @override
  Widget build(BuildContext context) {
    final total = _images.length + _videos.length;
    final heroH = _heroHeight(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final cacheW = (screenW * MediaQuery.devicePixelRatioOf(context)).round();

    if (total == 0) {
      return SizedBox(
        width: screenW,
        height: heroH,
        child: const ProductBrandedPlaceholder(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: screenW,
          height: heroH,
          child: CarouselSlider.builder(
            carouselController: _controller,
            itemCount: total,
            itemBuilder: (_, i, __) => _buildSlide(
              context,
              i,
              heroH,
              screenW,
              cacheW,
            ),
            options: CarouselOptions(
              height: heroH,
              viewportFraction: 1,
              enableInfiniteScroll: total > 1,
              enlargeCenterPage: false,
              onPageChanged: (i, _) {
                setState(() => _index = i);
                for (final c in _videoControllers.values) {
                  if (c.value.isPlaying) c.pause();
                }
              },
            ),
          ),
        ),
        if (_images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = i == _index && i < _images.length;
                return GestureDetector(
                  onTap: () => _controller.animateToPage(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? AppColor.primary : Colors.grey.shade300,
                        width: active ? 2.5 : 1,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColor.primary.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ProductDisplayImage(
                      url: _images[i],
                      width: 52,
                      height: 52,
                      memCacheWidth: 120,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (total > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 20 : 6,
                decoration: BoxDecoration(
                  color: active ? AppColor.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Tap image to zoom · Pinch to zoom in gallery',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(
    BuildContext context,
    int index,
    double heroH,
    double screenW,
    int cacheW,
  ) {
    final isImage = index < _images.length;
    if (isImage) {
      final url = _images[index];
      return GestureDetector(
        onTap: () => _openFullscreen(index),
        child: ProductDisplayImage(
          url: url,
          width: screenW,
          height: heroH,
          memCacheWidth: cacheW,
          heroTag: index == 0 ? widget.heroTag : null,
        ),
      );
    }

    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: controller.value.isPlaying ? 0 : 1,
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openFullscreen(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _FullscreenImageViewer(
          urls: _images,
          initialIndex: index,
        ),
      ),
    );
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late final PageController _pageController;
  late int _index;
  final Map<int, TransformationController> _transformControllers = {};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _transformControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TransformationController _controllerFor(int i) {
    return _transformControllers.putIfAbsent(i, TransformationController.new);
  }

  void _onDoubleTap(int pageIndex) {
    final c = _controllerFor(pageIndex);
    final scale = c.value.getMaxScaleOnAxis();
    if (scale > 1.05) {
      c.value = Matrix4.identity();
    } else {
      c.value = Matrix4.diagonal3Values(2.5, 2.5, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              return GestureDetector(
                onDoubleTap: () => _onDoubleTap(i),
                child: InteractiveViewer(
                  transformationController: _controllerFor(i),
                  minScale: 0.85,
                  maxScale: 5,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: ProductDisplayImage(
                      url: widget.urls[i],
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height * 0.85,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
