import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundScreen extends StatefulWidget {
  final String videoAsset;
  final String imageAsset;

  const VideoBackgroundScreen({
    super.key, // Updated to Key? to allow for nullable keys
    required this.videoAsset,
    required this.imageAsset,
  });

  @override
  _VideoBackgroundScreenState createState() => _VideoBackgroundScreenState();
}

class _VideoBackgroundScreenState extends State<VideoBackgroundScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      }).catchError((error) {
        print("Error initializing video: $error");
        setState(() {
          _isVideoInitialized = false;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildVideo() {
    if (_isVideoInitialized) {
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      // Backup image as a fallback
      return Image.asset(widget.imageAsset, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover, // Ensures the content covers the space
          child: _buildVideo(),
        ),
      ),
    );
  }
}
