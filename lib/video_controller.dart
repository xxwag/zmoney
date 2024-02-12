import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundScreen extends StatefulWidget {
  final String videoAsset;
  final String imageAsset;

  const VideoBackgroundScreen(
      {required Key key, required this.videoAsset, required this.imageAsset})
      : super(key: key);

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
        _controller.play();
        _controller.setLooping(true);
        setState(() {
          _isVideoInitialized = true;
        }); // when your controller is initialized.
      }).catchError((error) {
        // Handle video initialization error, e.g., file not found
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        // Container to define dedicated space
        width: double.infinity,
        height: double.infinity,
        child: _isVideoInitialized
            ? FittedBox(
                fit: BoxFit
                    .cover, // This will cover the space without stretching
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : FittedBox(
                fit: BoxFit
                    .cover, // This will cover the space without stretching
                child: Image.asset(widget.imageAsset),
              ),
      ),
    );
  }

  void showErrorDialogFragment() {
    // Your showErrorDialogFragment implementation
  }
}
