import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/offer_promo_video_card.dart';

/// Fullscreen pager over story offers.
class OfferStoryViewerScreen extends ConsumerStatefulWidget {
  const OfferStoryViewerScreen({
    super.key,
    required this.offers,
    required this.initialIndex,
  });

  final List<OfferBannerModel> offers;
  final int initialIndex;

  @override
  ConsumerState<OfferStoryViewerScreen> createState() =>
      _OfferStoryViewerScreenState();
}

class _OfferStoryViewerScreenState extends ConsumerState<OfferStoryViewerScreen> {
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.offers.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 52, 12, 28),
              child: OfferPromoVideoCard(
                offer: widget.offers[i],
                trackViewOnInit: false,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
