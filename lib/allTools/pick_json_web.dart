import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';

/// Web implementation: uses an HTML file input to pick a JSON file.
/// Returns a map with 'name' (String) and 'content' (dynamic — List or Map), or null if cancelled.
Future<Map<String, dynamic>?> pickJsonFromDevice() async {
  final completer = Completer<Map<String, dynamic>?>();

  final input = html.FileUploadInputElement()..accept = '.json';
  input.click();

  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsText(file);
    reader.onLoadEnd.listen((_) {
      try {
        final content = reader.result as String;
        final decoded = json.decode(content);
        if (decoded is! Map && decoded is! List) {
          completer.completeError('JSON must be an object or array.');
          return;
        }
        completer.complete({
          'name': file.name,
          'content': decoded,
        });
      } catch (e) {
        completer.completeError('Invalid JSON: $e');
      }
    });
    reader.onError.listen((_) {
      completer.completeError('Failed to read file.');
    });
  });

  // If the user cancels the dialog, the onChange event never fires.
  // We use a focus event on the window as a fallback.
  html.window.onFocus.first.then((_) {
    Future.delayed(Duration(milliseconds: 500), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
  });

  return completer.future;
}
