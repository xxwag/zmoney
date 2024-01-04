import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Axis scrollAxis;
  final CrossAxisAlignment crossAxisAlignment;
  final double blankSpace;
  final double velocity;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.scrollAxis = Axis.horizontal,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.blankSpace = 50.0,
    this.velocity = 50.0,
  });

  @override
  MarqueeTextState createState() => MarqueeTextState();
}

class MarqueeTextState extends State<MarqueeText> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll();
  }

  void _scroll() async {
    while (true) {
      await Future.delayed(
          const Duration(milliseconds: 100)); // Adjust the speed as needed
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        if (_scrollController.offset >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            _scrollController.offset + widget.blankSpace,
            duration: const Duration(
                milliseconds: 1000), // Adjust the duration as needed
            curve: Curves.linear,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: widget.scrollAxis,
      controller: _scrollController,
      child: Center(
        child: Text(
          widget.text,
          style: widget.style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
