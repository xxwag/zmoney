import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppPurchaseScreen extends StatefulWidget {
  const InAppPurchaseScreen({super.key});

  @override
  _InAppPurchaseScreenState createState() => _InAppPurchaseScreenState();
}

class _InAppPurchaseScreenState extends State<InAppPurchaseScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  double _availableZCoins = 0.0; // Variable to store available ZCoins

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadPlayerData(); // Load player data including ZCoins on init
  }

  void _initialize() async {
    _available = await _iap.isAvailable();
    if (_available) {
      await _getProducts();
    }
  }

  Future<void> _getProducts() async {
    Set<String> ids = {'emeraldskin', 'callspammerpass'}; // Your product IDs
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    setState(() {
      _products = response.productDetails;
    });
  }

  void _buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    String? playerDataString = prefs.getString('playerData');
    if (playerDataString != null) {
      Map<String, dynamic> playerData = jsonDecode(playerDataString);
      setState(() {
        _availableZCoins = playerData['total_win_amount']?.toDouble() ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store"),
        actions: [
          // Display available ZCoins
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'ZCoins: $_availableZCoins',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: _available
          ? ListView(
              children: _products
                  .map((product) => ListTile(
                        title: Text(product.title),
                        subtitle: Text(product.description),
                        trailing: TextButton(
                          child: Text(product.price),
                          onPressed: () => _buyProduct(product),
                        ),
                      ))
                  .toList(),
            )
          : const Center(child: Text("Store not available")),
    );
  }
}
