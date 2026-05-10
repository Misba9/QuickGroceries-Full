import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:video_player/video_player.dart';

/// Stable hero tag derived from a product id — used by [HomeProductCard]
/// and [ProductImageCarousel] so the image flies smoothly across screens.
String productHeroTag(String productId) => 'product-image-$productId';

/// Image + video carousel with cached images, dot indicators, and a
/// [Hero] on the first image so the transition from a list card feels
/// continuous.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({super.key, required this.product});
  final ProductModel product;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _index = 0;

  // Cached video controllers, keyed by carousel index.
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
    }
  }

  void _hydrateMedia() {
    final images = <String>[];
    if (widget.product.images.isNotEmpty) {
      images.addAll(widget.product.images.map((e) => e.toString()));
    } else if (widget.product.image.isNotEmpty) {
      images.add(widget.product.image);
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

  @override
  Widget build(BuildContext context) {
    final total = _images.length + _videos.length;
    if (total == 0) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey.shade100,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CarouselSlider.builder(
            carouselController: _controller,
            itemCount: total,
            itemBuilder: (_, i, __) => _buildSlide(i),
            options: CarouselOptions(
              viewportFraction: 1,
              enableInfiniteScroll: total > 1,
              autoPlay: total > 1,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (i, _) {
                setState(() => _index = i);
                for (final c in _videoControllers.values) {
                  if (c.value.isPlaying) c.pause();
                }
              },
            ),
          ),
        ),
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
                width: active ? 18 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColor.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildSlide(int index) {
    final isImage = index < _images.length;
    if (isImage) {
      final url = _images[index];
      Widget image = CachedImage(url: url, fit: BoxFit.contain);
      // Hero only on the first image — the source list cards use the same
      // tag, so multi-hero conflicts are avoided.
      if (index == 0) {
        image = Hero(
          tag: productHeroTag(widget.product.id),
          child: image,
        );
      }
      return Padding(
        padding: const EdgeInsets.all(12),
        child: image,
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

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
