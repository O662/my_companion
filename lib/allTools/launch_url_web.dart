import 'dart:html' as html;

/// Web implementation: opens a URL in a new browser tab.
/// Only launches http/https URLs to prevent dangerous URI schemes.
void launchUrlExternal(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    html.window.open(url, '_blank');
  }
}
