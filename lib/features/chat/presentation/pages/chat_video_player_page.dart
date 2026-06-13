import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Phát video chat fullscreen (URL Cloudinary).
class ChatVideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const ChatVideoPlayerPage({super.key, required this.videoUrl});

  @override
  State<ChatVideoPlayerPage> createState() => _ChatVideoPlayerPageState();
}

class _ChatVideoPlayerPageState extends State<ChatVideoPlayerPage> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          allowedScreenSleep: false,
        );
      });
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: _failed
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 48),
                  SizedBox(height: 8),
                  Text('Không phát được video',
                      style: TextStyle(color: Colors.white54)),
                ],
              )
            : _chewieController == null
                ? const CircularProgressIndicator(color: Colors.white)
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}
