import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/user/search_history_store.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/app_search_bar.dart';
import 'package:quickgrocery/core/widgets/sticky_search_bar.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/search/services/search_service.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    Provider.of<SearchService>(context, listen: false).fetchProducts();
    _loadSearchHistory();
    _initializeSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryStore.read();
    if (mounted) setState(() => _searchHistory = history);
  }

  void _runSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    Provider.of<SearchService>(context, listen: false).searchProducts(trimmed);
    SearchHistoryStore.add(trimmed).then((_) => _loadSearchHistory());
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
              _runSearch(result.recognizedWords);
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
    final gutter = Responsive.of(context).gutter();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('search'.tr()),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                StickySearchBar.asSliver(
                  gutter: gutter,
                  searchBar: AppSearchBar(
                    live: true,
                    autofocus: true,
                    focusNode: _focusNode,
                    controller: _searchController,
                    hints: ['search'.tr()],
                    onChanged: provider.searchProducts,
                    onSubmitted: _runSearch,
                    onMicTap: _startListening,
                    micActive: _isListening,
                    showMic: true,
                  ),
                ),
                if (_searchController.text.isEmpty && _searchHistory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent searches',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _searchHistory
                                .map(
                                  (q) => ActionChip(
                                    label: Text(q),
                                    onPressed: () {
                                      _searchController.text = q;
                                      _runSearch(q);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (provider.filteredProductsList == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.filteredProductsList!.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LottieBuilder.asset('assets/lottie/no_data.json'),
                          Text('no_filtered_products'.tr()),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 9,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
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
                        childCount: provider.filteredProductsList!.length,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
