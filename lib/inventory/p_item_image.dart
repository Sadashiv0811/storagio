import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/services/s_image.dart';

final itemImageProvider = Provider.autoDispose<ItemImageController>(
  (ref) => ItemImageController(),
);

class ItemImageController {
  final ImageService _imageService = ImageService();

  Future<String?> pickImage({String? oldPath}) async {
    final file = await _imageService.pickImage();
    if (file == null) return null;

    final newPath = await _imageService.saveImage(file);

    // delete old image if different
    if (oldPath != null && oldPath != newPath) {
      await _imageService.deleteImage(oldPath);
    }

    return newPath;
  }

  Future<String?> captureImageFromCamera({String? oldPath}) async {
    final file = await _imageService.captureImage();
    if (file == null) return null;

    final newPath = await _imageService.saveImage(file);

    // delete old image if different
    if (oldPath != null && oldPath != newPath) {
      await _imageService.deleteImage(oldPath);
    }

    return newPath;
  }
}
