import 'dart:convert';
import 'package:file_picker/file_picker.dart';

/// Mobile implementation using file_picker package.
/// Returns a map with 'name' (String) and 'content' (dynamic — List or Map), or null if cancelled.
Future<Map<String, dynamic>?> pickJsonFromDevice() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );

  if (result != null && result.files.single.bytes != null) {
    final bytes = result.files.single.bytes!;
    final content = utf8.decode(bytes);
    final decoded = json.decode(content);

    if (decoded is! Map && decoded is! List) {
      throw Exception('JSON must be an object or array.');
    }

    return {
      'name': result.files.single.name,
      'content': decoded,
    };
  }

  return null;
}
