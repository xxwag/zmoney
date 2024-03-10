import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundScreen extends StatefulWidget {
  final String videoAsset;
  final String imageAsset;

  const VideoBackgroundScreen({
    super.key,
    required this.videoAsset,
    required this.imageAsset,
  });

  @override
  VideoBackgroundScreenState createState() => VideoBackgroundScreenState();
}

class VideoBackgroundScreenState extends State<VideoBackgroundScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the VideoPlayerController with an asset source.
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        setState(() {
          // The video is now ready to be played.
          _isVideoInitialized = true;
        });
        // Optionally start playing the video automatically.
        _controller.play();
        // Loop the video indefinitely.
        _controller.setLooping(true);
      }).catchError((error) {
        setState(() {
          _isVideoInitialized = false;
        });
      });
  }

  @override
  void dispose() {
    // Ensure the controller is disposed to free up resources.
    _controller.dispose();
    super.dispose();
  }

  Widget _buildVideo() {
    if (_isVideoInitialized) {
      // The video is ready and can be displayed.
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      // Display a backup image while the video is not ready.
      return Image.asset(widget.imageAsset, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: _buildVideo(),
        ),
      ),
    );
  }
}
