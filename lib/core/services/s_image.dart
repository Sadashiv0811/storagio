import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:storagio/core/constants/static_values.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return null;

    return File(picked.path);
  }

  /// Save image with duplicate check
  Future<String> saveImage(File image) async {
    final Directory appDir = await getApplicationDocumentsDirectory();

    // Generate hash of image (for duplicate detection)
    final String hash = await _generateHash(image);

    final String fileName = '$hash${extension(image.path)}';
    logger.d("File name with hash: $fileName");
    final String newPath = join(appDir.path, fileName);

    final File newFile = File(newPath);

    // Check if already exists (same image)
    if (await newFile.exists()) {
      return newFile.path; // reuse existing file
    }

    // Optional: check if source path already inside app directory
    if (image.path == newPath) {
      return image.path;
    }

    final File savedImage = await image.copy(newPath);
    return savedImage.path;
  }

  /// Get image safely
  File? getImage(String path) {
    final file = File(path);

    if (file.existsSync()) {
      return file;
    }

    return null;
  }

  /// Delete image
  Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);

      if (!await file.exists()) {
        return false;
      }

      await file.delete();

      return !(await file.exists());
    } catch (e) {
      logger.d('Failed to delete image: $e');
      return false;
    }
  }

  /// Generate hash (MD5)
  Future<String> _generateHash(File file) async {
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }

  /// Capture image from camera
  Future<File?> captureImage() async {
    final XFile? captured = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (captured == null) return null;

    return File(captured.path);
  }

  /// CONVERT IMAGE TO BASE64
  Future<String?> imageToBase64(String? imagePath) async {
    if (imagePath == null) {
      return null;
    }

    final file = File(imagePath);

    if (!await file.exists()) {
      return null;
    }

    // Compress image
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,

      minWidth: 512,
      minHeight: 512,

      quality: 50,
    );

    if (compressedBytes == null) {
      return null;
    }

    return base64Encode(compressedBytes);
  }

  /// BASE64 TO IMAGE FILE
  Future<String?> base64ToImage(String? base64String) async {
    if (base64String == null) {
      return null;
    }

    final bytes = base64Decode(base64String);

    final dir = await getApplicationDocumentsDirectory();

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final file = File(join(dir.path, fileName));

    await file.writeAsBytes(bytes);

    return file.path;
  }
}
