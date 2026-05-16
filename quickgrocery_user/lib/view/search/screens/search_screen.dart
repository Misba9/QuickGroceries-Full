import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/search/services/search_service.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/svg.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeechAvailable = false;

  @override
  void initState() {
    super.initState();
    Provider.of<SearchService>(context, listen: false).fetchProducts();
    _initializeSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {
            _isListening = status == 'listening';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition error: ${error.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
    if (mounted) {
      setState(() {
        _isSpeechAvailable = available;
      });
    }
  }

  Future<void> _startListening() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice search'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_isSpeechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            if (result.finalResult) {
              setState(() {
                _isListening = false;
              });
              _searchController.text = result.recognizedWords;
              Provider.of<SearchService>(
                context,
                listen: false,
              ).searchProducts(result.recognizedWords);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchService>(context);
    return Scaffold(
      appBar: AppBar(title: Text('search'.tr())),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icons/Search.svg'),
                      AppSpacing.w20,
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (query) {
                            provider.searchProducts(query);
                          },
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'search'.tr(),
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.w10,
                      GestureDetector(
                        onTap: _startListening,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                                color: _isListening
                                    ? AppColor.primary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? AppColor.primary
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.filteredProductsList == null
                      ? const Column(children: [CircularProgressIndicator()])
                      : provider.filteredProductsList!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LottieBuilder.asset('assets/lottie/no_data.json'),
                              Text('no_filtered_products'.tr()),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.64,
                          ),
                          itemCount: provider.filteredProductsList!.length,
                          itemBuilder: (context, i) {
                            final product = provider.filteredProductsList![i];
                            return LayoutBuilder(
                              builder: (context, c) {
                                return ProductCardWidget(
                                  product: product,
                                  width: c.maxWidth,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: FloatingCartPill.positionedBottomFullScreen(context),
              child: const FloatingCartPill(),
            ),
          ],
        ),
      ),
    );
  }
}
