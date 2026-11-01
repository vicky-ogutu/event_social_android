import 'package:image_picker/image_picker.dart';

/// Opens the system photo picker and returns a local path, or `null` if the
/// user cancelled. Images are downscaled to keep uploads fast.
Future<String?> pickImagePath({double maxWidth = 1600}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
    imageQuality: 85,
  );
  return file?.path;
}

/// Lets the user pick up to [limit] photos; returns their local paths.
Future<List<String>> pickImagePaths({int limit = 4, double maxWidth = 1600}) async {
  final files = await ImagePicker().pickMultiImage(maxWidth: maxWidth, imageQuality: 85, limit: limit);
  return files.take(limit).map((f) => f.path).toList();
}
