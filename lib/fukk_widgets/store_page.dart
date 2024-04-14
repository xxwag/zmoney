import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zmoney/fukk_widgets/ngrok.dart';

class InAppPurchaseScreen extends StatefulWidget {
  const InAppPurchaseScreen({super.key});

  @override
  InAppPurchaseScreenState createState() => InAppPurchaseScreenState();
}

class InAppPurchaseScreenState extends State<InAppPurchaseScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  double _availableZCoins = 0.0;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Dio _dio = Dio();
  Map<String, int> _productQuantities =
      {}; // Holds the quantities of purchased products

  @override
  void initState() {
    super.initState();
    _initialize();
    final Stream<List<PurchaseDetails>> purchaseUpdates = _iap.purchaseStream;
    _subscription = purchaseUpdates.listen((purchases) {
      _handlePurchaseUpdates(purchases);
    });
  }

  void _initialize() async {
    _available = await _iap.isAvailable();
    if (_available) {
      await _getProducts();
      await _loadInventory();
      await _loadPlayerData();
    }
  }

  Future<void> _getProducts() async {
    Set<String> ids = {'emeraldskin', 'callspammerpass'};
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    setState(() {
      _products = response.productDetails;
    });
  }

  void _buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _saveInventory() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert _productQuantities map to a list of maps for storage
    List<Map<String, dynamic>> inventoryList =
        _productQuantities.entries.map((entry) {
      return {
        "productId": entry.key,
        "quantity": entry.value,
        "purchaseDate":
            DateTime.now().toIso8601String(), // Example, adjust as needed
      };
    }).toList();

    await prefs.setString('inventory', jsonEncode(inventoryList));
  }

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    String? inventoryString = prefs.getString('inventory');
    print(inventoryString);
    if (inventoryString != null) {
      List<dynamic> inventoryList = jsonDecode(inventoryString);
      _productQuantities = {
        for (var item in inventoryList) item['productId']: item['quantity']
      };
    }
  }

  Future<void> _updatePurchaseToBackend(
      String productId, bool isZCoinPurchase, int quantity) async {
    final secureStorage = FlutterSecureStorage();
    final String endpoint = "${NgrokManager.ngrokUrl}/api/purchase";
    final String? jwtToken = await secureStorage.read(key: 'jwtToken');

    try {
      final response = await _dio.post(
        endpoint,
        data: {
          'productId': productId,
          'isZCoinPurchase': isZCoinPurchase,
          'quantity': quantity,
        },
        options: Options(headers: {'Authorization': 'Bearer $jwtToken'}),
      );

      if (response.statusCode == 200) {
        print('Purchase updated successfully with quantity $quantity');
      } else {
        print('Failed to update purchase');
      }
    } catch (e) {
      print('Error contacting the backend: $e');
    }
  }

  double getPriceInZCoins(String priceString) {
    final price =
        double.tryParse(priceString.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return price * 10000;
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

  Future<void> _savePlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> playerData = {'total_win_amount': _availableZCoins};
    prefs.setString('playerData', jsonEncode(playerData));
  }

  Future<void> _buyWithZCoins(ProductDetails prod) async {
    Set<String> incrementalProducts = {'callspammerpass'};
    final bool isIncrementalProduct = incrementalProducts.contains(prod.id);
    final double zCoinPrice = getPriceInZCoins(prod.price);
    int currentQuantity = _productQuantities[prod.id] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int purchaseQuantity = 1; // Default purchase quantity
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isIncrementalProduct
                  ? "Select Quantity"
                  : "Confirm Purchase"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Current quantity: $currentQuantity"),
                  isIncrementalProduct
                      ? Slider(
                          min: 1,
                          max: 10, // Adjust as needed
                          divisions: 9,
                          value: purchaseQuantity.toDouble(),
                          onChanged: (double value) {
                            setState(() => purchaseQuantity = value.toInt());
                          },
                          label: "$purchaseQuantity",
                        )
                      : const SizedBox(),
                  Text("Total cost: ${zCoinPrice * purchaseQuantity} ZCoins"),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text("Buy"),
                  onPressed: () async {
                    if (_availableZCoins >= zCoinPrice * purchaseQuantity) {
                      setState(() {
                        _availableZCoins -= zCoinPrice * purchaseQuantity;
                        _productQuantities[prod.id] =
                            currentQuantity + purchaseQuantity;
                      });
                      await _updatePurchaseToBackend(
                          prod.id, true, currentQuantity + purchaseQuantity);
                      _saveInventory(); // Update local inventory with new quantities
                      Navigator.of(context).pop();
                    } else {
                      print("Insufficient ZCoins");
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased &&
          purchase.pendingCompletePurchase) {
        final int purchasedQuantity =
            await MethodChannel('com.gg.zmoney/game_services').invokeMethod(
                'retrievePurchasedQuantity', {'productId': purchase.productID});

        setState(() {
          _productQuantities[purchase.productID] = purchasedQuantity;
        });

        await _updatePurchaseToBackend(
            purchase.productID, false, purchasedQuantity);
        _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        // Handle errors
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store"),
        actions: [
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
          ? ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return FutureBuilder<ImageProvider>(
                  future: _getImageProviderForProduct(product.id),
                  builder: (BuildContext context,
                      AsyncSnapshot<ImageProvider> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return _buildProductItem(
                          context, product, snapshot.data!);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                );
              },
            )
          : const Center(child: Text("Store not available")),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductDetails product,
      ImageProvider imageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  product.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: Text(product.price),
                  onPressed: () => _buyProduct(product),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                      "Buy with ZCoins (${getPriceInZCoins(product.price)} ZCoins)"),
                  onPressed: () => _buyWithZCoins(product),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<ImageProvider> _getImageProviderForProduct(String productId) async {
    Map<String, dynamic> imageSourceMap = {
      'emeraldskin': 'textures/texture2.jpg',
      'callspammerpass': 'assets/mainscreen.png',
    };

    var imageSource = imageSourceMap[productId];
    if (imageSource == null) {
      return const AssetImage('assets/images/default.jpg');
    }

    if (imageSource is String && imageSource.startsWith('assets/')) {
      return AssetImage(imageSource);
    } else if (imageSource is String) {
      final directory = await getApplicationDocumentsDirectory();
      return FileImage(File('${directory.path}/$imageSource'));
    } else {
      return const AssetImage('assets/images/default.jpg');
    }
  }
}
