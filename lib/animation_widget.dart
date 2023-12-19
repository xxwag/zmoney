import 'package:flutter/material.dart';

class FlipAnimationWidget extends StatefulWidget {
  final int digit;
  const FlipAnimationWidget({super.key, required this.digit});

  @override
  _FlipAnimationWidgetState createState() => _FlipAnimationWidgetState();
}

class _FlipAnimationWidgetState extends State<FlipAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
  }

  @override
  void didUpdateWidget(FlipAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateX(2 * 3.14 * _animation.value),
      child: Text(
        widget.digit.toString(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Digital-7',
        ),
      ),
    );
  }
}
