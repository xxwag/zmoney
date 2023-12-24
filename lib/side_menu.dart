import 'package:flutter/material.dart';

class SideMenuDrawer extends StatefulWidget {
  final List<String> translatedTexts;
  final int marqueeThreshold = 20; // Threshold for applying Marquee
  final Color containerColor; // Color for the background container

  const SideMenuDrawer({
    super.key,
    required this.translatedTexts,
    required this.containerColor,
  });

  @override
  SideMenuDrawerState createState() => SideMenuDrawerState();
}

class SideMenuDrawerState extends State<SideMenuDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: widget.containerColor, // Set the background color here
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.translatedTexts[
                      10], // Using a translated text for the title
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 10),
                // Using other translated texts for game rules or additional info
                Text(
                  widget.translatedTexts[11], // 'Game Rule 1' or equivalent
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  widget.translatedTexts[12], // 'Game Rule 2' or equivalent
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                // Add more texts as needed...
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: Text(widget.translatedTexts[13]), // 'Messages' or equivalent
            onTap: () {
              // Handle the tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(widget.translatedTexts[14]), // 'Profile' or equivalent
            onTap: () {
              // Handle the tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(widget.translatedTexts[14]), // 'Settings' or equivalent
            onTap: () {
              // Handle the tap
            },
          ),
          // Add more ListTiles for additional menu items...
        ],
      ),
    );
  }
}
