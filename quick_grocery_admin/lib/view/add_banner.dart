import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class AddBannerScreen extends StatefulWidget {
  const AddBannerScreen({super.key});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  @override
  void initState() {
    Provider.of<DashBoardServices>(context, listen: false).fetchBanners();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashBoardServices>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryAppBar(),
            AppSpacing.h20,
            WrapperWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banner Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.h10,
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            provider.setBannerType('image');
                          },
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: provider.bannerType == 'image'
                                    ? AppColor.primary
                                    : Colors.grey.shade300,
                                width: provider.bannerType == 'image' ? 2 : 1,
                              ),
                              color: provider.bannerType == 'image'
                                  ? AppColor.primary.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  color: provider.bannerType == 'image'
                                      ? AppColor.primary
                                      : Colors.grey,
                                ),
                                AppSpacing.w10,
                                Text(
                                  'Image',
                                  style: TextStyle(
                                    color: provider.bannerType == 'image'
                                        ? AppColor.primary
                                        : Colors.grey,
                                    fontWeight: provider.bannerType == 'image'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.w10,
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            provider.setBannerType('video');
                          },
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: provider.bannerType == 'video'
                                    ? AppColor.primary
                                    : Colors.grey.shade300,
                                width: provider.bannerType == 'video' ? 2 : 1,
                              ),
                              color: provider.bannerType == 'video'
                                  ? AppColor.primary.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_library,
                                  color: provider.bannerType == 'video'
                                      ? AppColor.primary
                                      : Colors.grey,
                                ),
                                AppSpacing.w10,
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    color: provider.bannerType == 'video'
                                        ? AppColor.primary
                                        : Colors.grey,
                                    fontWeight: provider.bannerType == 'video'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h20,
                  Text(
                    provider.bannerType == 'image'
                        ? 'Banner Image'
                        : 'Banner Video',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.h10,
                  Container(
                    height: MediaQuery.of(context).size.width * .20,
                    width: MediaQuery.of(context).size.width * .80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: provider.bannerType == 'image'
                          ? (provider.imageBytes == null
                                ? Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  )
                                : Image.memory(provider.imageBytes!))
                          : (provider.videoPath == null &&
                                    provider.videoBytes == null
                                ? Icon(
                                    Icons.video_library,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Video thumbnail or placeholder
                                        kIsWeb
                                            ? Container(
                                                color: Colors.black,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.video_library,
                                                        size: 60,
                                                        color: Colors.white70,
                                                      ),
                                                      AppSpacing.h10,
                                                      Text(
                                                        'Video Selected',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : provider.videoPath != null
                                            ? Image.file(
                                                File(provider.videoPath!),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: Colors.black,
                                                        child: Icon(
                                                          Icons.video_library,
                                                          color: Colors.white,
                                                          size: 40,
                                                        ),
                                                      );
                                                    },
                                              )
                                            : Container(
                                                color: Colors.black,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.video_library,
                                                        size: 60,
                                                        color: Colors.white70,
                                                      ),
                                                      AppSpacing.h10,
                                                      Text(
                                                        'Video Selected',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        // Play button overlay
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                    ),
                  ),
                  AppSpacing.h20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (provider.bannerType == 'image') {
                            provider.pickImage();
                          } else {
                            provider.pickVideo();
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * .12,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add),
                              AppSpacing.w10,
                              Text(
                                provider.bannerType == 'image'
                                    ? 'Upload Image'
                                    : 'Upload Video',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: SizedBox(
                            height: 40,
                            width: 300,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColor.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => provider.addBanner(context),
                              child: provider.isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 1,
                                      ),
                                    )
                                  : Text('Submit'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            provider.banners == null
                ? LinearProgressIndicator()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: provider.banners!.length,
                    itemBuilder: (context, i) {
                      final banner = provider.banners![i];
                      return Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Stack(
                          children: [
                            Container(
                              height: 300,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GestureDetector(
                                  onTap:
                                      banner.isVideo && banner.video.isNotEmpty
                                      ? () => _showVideoPlayer(
                                          context,
                                          banner.video,
                                        )
                                      : null,
                                  child: banner.isVideo
                                      ? _buildVideoBanner(banner)
                                      : _buildImageBanner(banner),
                                ),
                              ),
                            ),
                            if (banner.isVideo)
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.video_library,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      AppSpacing.w5,
                                      Text(
                                        'Video',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                onPressed: () {
                                  showDeleteDialog(context, () {
                                    provider.deleteBanner(banner.id);
                                  });
                                },
                                icon: Icon(Icons.delete, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBanner(BannerModel banner) {
    return Stack(
      fit: StackFit.expand,
      children: [
        banner.video.isNotEmpty
            ? Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        size: 60,
                        color: Colors.white,
                      ),
                      AppSpacing.h10,
                      Text(
                        'Video Banner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppSpacing.h5,
                      Text(
                        'Tap to view',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                color: Colors.grey.shade800,
                child: Center(
                  child: Icon(
                    Icons.video_library,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
      ],
    );
  }

  void _showVideoPlayer(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  Widget _buildImageBanner(BannerModel banner) {
    if (banner.image.isNotEmpty) {
      return Image.network(
        banner.image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey.shade300,
        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
      );
    }
  }

  void showDeleteDialog(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete this banner? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Banner deleted successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      _controller.play();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: Colors.white))
            else if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 50),
                    AppSpacing.h10,
                    Text(
                      'Error loading video',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            else if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Play/Pause button overlay
            if (_isInitialized && !_hasError)
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
