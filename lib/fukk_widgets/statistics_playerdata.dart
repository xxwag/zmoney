import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/fukk_widgets/translator.dart';

final translator =
    Translator(currentLanguage: 'en'); // Set initial language as needed

class PlayerDataWidget extends StatefulWidget {
  final double conversionRatio;

  const PlayerDataWidget({super.key, required this.conversionRatio});

  @override
  PlayerDataWidgetState createState() => PlayerDataWidgetState();
}

class PlayerDataWidgetState extends State<PlayerDataWidget> {
  Map<String, dynamic> playerData = {};
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _loadUserEmail();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    String? playerDataString = prefs.getString('playerData');
    if (playerDataString != null) {
      Map<String, dynamic> tempPlayerData = jsonDecode(playerDataString);

      // Ensuring 'total_win_amount' is treated as a double
      if (tempPlayerData.containsKey('total_win_amount')) {
        var totalWinAmount = tempPlayerData['total_win_amount'];
        // Convert to double if it is not already
        tempPlayerData['total_win_amount'] =
            totalWinAmount is int ? totalWinAmount.toDouble() : totalWinAmount;
      }

      setState(() {
        playerData = tempPlayerData;
      });
    }
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
  }

  void _showAchievements() async {
    await GamesServices.showAchievements();
  }

  void _showLeaderboard() async {
    await GamesServices.showLeaderboards(); // Use your actual leaderboard ID
  }

  @override
  Widget build(BuildContext context) {
    // Assuming playerData['total_win_amount'] and conversionRatio are correctly fetched/set
    // Assuming playerData is a map

    final double totalWinAmount =
        (playerData['total_win_amount'] as double?) ?? 0.1;

// Calculate the initial real money value
    final double conversionRatio =
        widget.conversionRatio; // Default to 0.0 if not provided
    final double initialRealMoneyValue =
        (totalWinAmount * conversionRatio) * 0.60; // Adjusted formula

// Calculate 60% of the initial real money value
    final double realMoneyValue = initialRealMoneyValue;
    List<String> lastGuesses =
        playerData['last_guesses']?.toString().split(',') ?? [];

    return Material(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _showAchievements,
                    child: const Text('Achievements'),
                  ),
                  ElevatedButton(
                    onPressed: _showLeaderboard,
                    child: const Text('Leaderboard'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FutureBuilder<String>(
                      future: translator.translate("Wins"),
                      builder: (context, snapshot) => _buildHighlightedInfo(
                          title: snapshot.data ?? "Wins",
                          value: playerData['wins']?.toString() ?? '0'),
                    ),
                    FutureBuilder<String>(
                      future: translator.translate("Total Guesses"),
                      builder: (context, snapshot) => _buildHighlightedInfo(
                          title: snapshot.data ?? "Total Guesses",
                          value:
                              playerData['total_guesses']?.toString() ?? '0'),
                    ),
                  ],
                ),
              ),
              if (userEmail != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FutureBuilder<String>(
                    future: translator.translate("Logged in as"),
                    builder: (context, snapshot) {
                      String loggedInText = snapshot.data ?? "Logged in as";
                      return Text(
                        "$loggedInText: $userEmail",
                        style: const TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      );
                    },
                  ),
                ),
              FutureBuilder<String>(
                future: translator.translate("Earnings"),
                builder: (context, snapshot) =>
                    _buildSectionTitle(snapshot.data ?? "Earnings"),
              ),
              FutureBuilder<String>(
                future: translator.translate("Total Win Amount"),
                builder: (context, snapshot) => _buildAmountRow(
                    snapshot.data ?? "Total Win Amount:", totalWinAmount,
                    leadingIcon: Icons.account_balance_wallet),
              ),
              FutureBuilder<String>(
                future: translator.translate("Real Money Value"),
                builder: (context, snapshot) => _buildAmountRowWithExplanation(
                    snapshot.data ?? "Real Money Value:", realMoneyValue,
                    leadingIcon: Icons.monetization_on, isCurrency: true),
              ),
              const Divider(),
              FutureBuilder<String>(
                future: translator.translate("Highest Win"),
                builder: (context, snapshot) =>
                    _buildSectionTitle(snapshot.data ?? "Highest Win"),
              ),
              FutureBuilder<String>(
                future: translator.translate("Highest Win Amount"),
                builder: (context, snapshot) => _buildAmountRow(
                    snapshot.data ?? "Highest Win Amount:", totalWinAmount,
                    leadingIcon: Icons.emoji_events),
              ),
              const Divider(),
              FutureBuilder<String>(
                future: translator.translate("Last Guesses"),
                builder: (context, snapshot) =>
                    _buildSectionTitle(snapshot.data ?? "Last Guesses"),
              ),
              lastGuesses.isNotEmpty
                  ? Column(
                      children: lastGuesses
                          .map((guess) => ListTile(
                                leading: const Icon(Icons.casino,
                                    color: Colors.orange),
                                title: Text(guess,
                                    style: const TextStyle(fontSize: 16)),
                              ))
                          .toList(),
                    )
                  : FutureBuilder<String>(
                      future: translator.translate("No last guesses available"),
                      builder: (context, snapshot) => Text(
                          snapshot.data ?? "No last guesses available",
                          style: const TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRowWithExplanation(String title, double amount,
      {bool isCurrency = false, IconData? leadingIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountRow(title, amount,
            isCurrency: isCurrency, leadingIcon: leadingIcon),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: FutureBuilder<String>(
            future: translator.translate(
                "**current revenue + your score * your total win amount"), // Request translation for this text
            builder: (context, snapshot) {
              // Use AutoSizeText with translated text if available
              return SizedBox(
                width: double.infinity,
                child: AutoSizeText(
                  snapshot.hasData
                      ? snapshot.data!
                      : '', // Display translated text if available, else empty string
                  maxLines: 1,
                  minFontSize: 5,
                  maxFontSize: 15,
                  style: TextStyle(
                    fontFamily: 'Proxima',
                    fontSize: 12, // Adjust the size as needed
                    fontStyle: FontStyle
                        .italic, // Use italic for the explanation if desired
                    color: Colors
                        .grey, // Use a subtle color to indicate this is an explanation
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedInfo({required String title, required String value}) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildAmountRow(String title, double amount,
      {bool isCurrency = false, IconData? leadingIcon}) {
    return ListTile(
      leading: leadingIcon != null ? Icon(leadingIcon) : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        isCurrency
            ? '\$${amount.toStringAsFixed(2)}'
            : '${amount.toString()} Coins',
        style: const TextStyle(
            color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
// Assuming PlayerDataWidget is defined elsewhere in your code

class StatisticsFloatingButton extends StatefulWidget {
  final double conversionRatio; // Add conversionRatio as a field

  const StatisticsFloatingButton({
    super.key,
    required this.conversionRatio, // Require it as a named parameter
  });

  @override
  State<StatisticsFloatingButton> createState() =>
      _StatisticsFloatingButtonState();
}

class _StatisticsFloatingButtonState extends State<StatisticsFloatingButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  bool isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleOverlay(BuildContext context) {
    if (isOverlayVisible) {
      _hideOverlay();
    } else {
      _showOverlay(context);
    }
  }

  void _showOverlay(BuildContext context) {
    _overlayEntry = _createOverlayEntry(context);
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    isOverlayVisible = true;
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((value) => _overlayEntry?.remove());
      isOverlayVisible = false;
    }
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    // Animation for slide transition
    var slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0), // Start from the right
      end: Offset.zero, // End at its natural position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Tracking start and end points of the swipe
    Offset? dragStart;
    Offset? dragEnd;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideOverlay, // Close drawer when tapping outside
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent area
            Positioned.fill(
              child: Container(
                  color: Colors.black54), // Semi-transparent background
            ),
            // Drawer
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: slideAnimation,
                child: Material(
                  elevation: 16.0, // Shadow
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        dragStart = details.globalPosition;
                      },
                      onHorizontalDragUpdate: (details) {
                        dragEnd = details.globalPosition;
                      },
                      onHorizontalDragEnd: (details) {
                        // Determine swipe direction and velocity
                        final velocity = details.primaryVelocity ?? 0;
                        // Close drawer if swipe to the right or fast swipe to the left
                        if (dragEnd!.dx > dragStart!.dx || velocity > 250) {
                          _hideOverlay();
                        }
                      },
                      child: Column(
                        children: [
                          AppBar(
                            title: const Text("Player Stats"),
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed:
                                  _hideOverlay, // Back button to close the drawer
                            ),
                            automaticallyImplyLeading: false,
                          ),
                          Expanded(
                            child: PlayerDataWidget(
                                conversionRatio: widget
                                    .conversionRatio), // Use widget.conversionRatio here
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, // Specify the width
      height: 80, // Specify the height
      child: FloatingActionButton(
        onPressed: () => _toggleOverlay(context),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 22.0, top: 22.0), // Adjust padding as needed
          child: Align(
            alignment:
                Alignment.topLeft, // Aligns the icon to the top-left corner
            child: Icon(isOverlayVisible ? Icons.close : Icons.bar_chart,
                size: 30), // You can adjust the icon size too
          ),
        ),
        // Customizing the shape
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(50)), // Adjusted roundness
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
