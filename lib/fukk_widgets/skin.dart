import 'package:flutter/material.dart';

class Skin {
  final Color backgroundColor;
  final Color prizePoolTextColor;
  final Color textColor;
  final Color specialTextColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final BoxDecoration decoration;
  final Color textColorSwitchTrue; // Color when switch condition is true
  final Color textColorSwitchFalse; // Color when switch condition is false

  Skin({
    required this.backgroundColor,
    required this.prizePoolTextColor,
    required this.textColor,
    required this.specialTextColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.decoration,
    required this.textColorSwitchTrue,
    required this.textColorSwitchFalse,
  });
}
