import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen dialog for previewing saved video banners.
class BannerVideoPlayerDialog extends StatefulWidget {
  const BannerVideoPlayerDialog({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<BannerVideoPlayerDialog> createState() => _BannerVideoPlayerDialogState();
}

class _BannerVideoPlayerDialogState extends State<BannerVideoPlayerDialog> {
  VideoPlayerController? _controller;
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
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      _controller = c;
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      await c.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_hasError)
              const Center(
                child: Text(
                  'Could not load video',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_isInitialized && !_hasError && _controller != null)
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      if (!mounted || _controller == null) return;
                      final c = _controller!;
                      if (c.value.isPlaying) {
                        await c.pause();
                      } else {
                        await c.play();
                      }
                      if (!mounted) return;
                      setState(() {});
                    },
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
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
