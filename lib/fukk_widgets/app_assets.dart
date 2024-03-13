import 'dart:io';
// ignore: unused_import
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Represents an asset that the app requires.
class AppAsset {
  final String cloudPath; // Path in Firebase Storage
  final String localPath; // Local path within the app's directory

  AppAsset({required this.cloudPath, required this.localPath});

  @override
  String toString() {
    // Custom toString to make it easier to log asset information
    return 'AppAsset(cloudPath: $cloudPath, localPath: $localPath)';
  }
}

Directory? appDocumentsDirectory;

/// Checks for the presence of specified assets in the local file system
/// and fetches them from Firebase Storage if they are not found.
Future<bool> checkAndFetchAssets() async {
  final FirebaseStorage storage = FirebaseStorage.instance;

  try {
    appDocumentsDirectory = await getApplicationDocumentsDirectory();
    final List<String> assetCategories = [
      'assets/videos',
      'assets/textures',
      'assets/sounds'
    ];

    for (String category in assetCategories) {
      // List all assets within each category
      ListResult result = await storage.ref(category).listAll();

      for (var item in result.items) {
        String cloudPath = item.fullPath;
        String localPath = cloudPath.replaceFirst('assets/', '');
        AppAsset asset = AppAsset(cloudPath: cloudPath, localPath: localPath);

        final File localFile =
            File(p.join(appDocumentsDirectory!.path, asset.localPath));

        if (!await localFile.exists() || await localFile.length() == 0) {
          await fetchAndSaveAsset(asset.cloudPath, localFile);
        } else {}
      }
    }

    return true; // Return true on success
  } catch (e) {
    return false; // Return false on error
  }
}

/// Fetches an asset from Firebase Storage and saves it locally.
Future<void> fetchAndSaveAsset(String cloudPath, File localFile) async {
  final FirebaseStorage storage = FirebaseStorage.instance;
  try {
    final String downloadUrl = await storage.ref(cloudPath).getDownloadURL();
    final Dio dio = Dio();

    Response response = await dio.get(
      downloadUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    await localFile.create(recursive: true);
    await localFile.writeAsBytes(response.data);
  } catch (e) {
    // It's helpful to log errors for debugging purposes
    return;
  }
}
