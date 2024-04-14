import 'package:flutter/material.dart';

class Skin {
  final Color backgroundColor;
  final Color prizePoolTextColor;
  final Color textColor;
  final Color specialTextColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color overlayButtonColor1;
  final BoxDecoration decoration;
  final Color textColorSwitchTrue; // Color when switch condition is true
  final Color textColorSwitchFalse; // Color when switch condition is false
  final String id; // Add an ID for each skin
  bool isAvailable; // Mark if the skin is available based on inventory

  Skin({
    required this.overlayButtonColor1,
    required this.backgroundColor,
    required this.prizePoolTextColor,
    required this.textColor,
    required this.specialTextColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.decoration,
    required this.textColorSwitchTrue,
    required this.textColorSwitchFalse,
    required this.id, // Require an ID
    this.isAvailable = false, // Default to false, updated based on inventory
  });
}
