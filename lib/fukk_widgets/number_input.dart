import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class NumberInputField extends StatefulWidget {
  final Size screenSize;
  final String hintText;
  final Color primaryColor;
  final Color secondaryColor;
  final Color thirdColor;
  final Color fifthColor;
  final TextEditingController controller; // Add this line

  const NumberInputField({
    Key? key,
    required this.screenSize,
    required this.hintText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.thirdColor,
    required this.fifthColor,
    required this.controller, // Add this line
  }) : super(key: key);

  @override
  _NumberInputFieldState createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<NumberInputField> {
  final FocusNode _focusNode = FocusNode();

  bool _isFieldFocused = false;

  BorderRadius textFieldBorderRadius = BorderRadius.circular(10);
  List<BoxShadow> textFieldShadow = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFieldFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: SizedBox(
        width: widget.screenSize.width * 0.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: widget.screenSize.width * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: widget.fifthColor,
                borderRadius: textFieldBorderRadius,
                boxShadow: textFieldShadow,
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 48, minHeight: 22),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                  letterSpacing: 1.2,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            AnimatedOpacity(
                opacity: _isFieldFocused || widget.controller.text.isNotEmpty
                    ? 0.0
                    : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          FocusScope.of(context).requestFocus(_focusNode),
                      child: Container(
                        width: widget.screenSize.width * 0.8,
                        height: 48, // Adjust based on your TextField's height
                        alignment: Alignment.center,
                        child: AnimatedTextKit(
                          animatedTexts: [
                            FlickerAnimatedText(
                              'PLAY',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                              speed: const Duration(milliseconds: 550),
                            ),
                            FlickerAnimatedText(
                              'THE BEST GAME',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                              speed: const Duration(milliseconds: 600),
                            ),
                            FlickerAnimatedText(
                              'Now!!',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                              speed: const Duration(milliseconds: 1200),
                            ),
                            TypewriterAnimatedText(
                              'Enter your lucky number here',
                              textStyle: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                                letterSpacing: 1.2,
                                fontFamily: 'Inter',
                              ),
                              speed: const Duration(milliseconds: 200),
                            ),
                            FlickerAnimatedText(
                              'PLAY',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                              speed: const Duration(milliseconds: 600),
                            ),
                            FlickerAnimatedText(
                              'THE BEST GAME',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                              speed: const Duration(milliseconds: 600),
                            ),
                            FlickerAnimatedText(
                              'Now!!',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                              speed: const Duration(milliseconds: 200),
                            ),
                            /* WavyAnimatedText(
                              widget.hintText,
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontStyle: FontStyle.italic,
                                color: widget.primaryColor,
                              ),
                            ),*/
                            FadeAnimatedText(
                              widget.hintText,
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                decoration: TextDecoration.none,
                                fontSize: 15.0,
                                color: widget.primaryColor,
                              ),
                            ),
                            /* RotateAnimatedText(
                              widget.hintText,
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont2',
                                fontSize: 15.0,
                                color: widget.primaryColor,
                              ),
                            ),*/
                            ScaleAnimatedText(
                              scalingFactor: 1.2,
                              'You can do it! I trust you!',
                              textStyle: TextStyle(
                                fontFamily: 'CartoonFont4',
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                            ),
                            TypewriterAnimatedText(
                              'What are you waiting for? Invitation?',
                              textStyle: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                                letterSpacing: 1.2,
                                fontFamily: 'Inter',
                              ),
                              speed: const Duration(milliseconds: 200),
                            ),
                            TypewriterAnimatedText(
                              'Now seriously please enter your numbers!',
                              textStyle: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                                letterSpacing: 1.2,
                                fontFamily: 'Inter',
                              ),
                              speed: const Duration(milliseconds: 200),
                            ),
                          ],
                          onNext: (index, reason) {
                            setState(() {
                              // Dynamically update the TextField's appearance

                              textFieldBorderRadius =
                                  BorderRadius.circular((index % 4 + 1) * 10.0);
                              textFieldShadow = [
                                BoxShadow(
                                  color: widget.thirdColor,
                                  spreadRadius: (index % 4 + 1) * 1.0,
                                  blurRadius: (index % 4 + 1) * 3.0,
                                  offset: Offset(0, (index % 4 + 1) * 1.0),
                                ),
                              ];
                            });
                          },
                          onTap: () =>
                              FocusScope.of(context).requestFocus(_focusNode),
                          repeatForever: true,
                          pause: const Duration(milliseconds: 500),
                          displayFullTextOnTap: false,
                          stopPauseOnTap: false,
                          // Specify other properties as needed
                        ),
                      ),
                    )))
          ],
        ),
      ),
    );
  }
}
