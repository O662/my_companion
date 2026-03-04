import 'package:url_launcher/url_launcher.dart';

/// Mobile implementation using url_launcher package.
/// Only launches http/https URLs to prevent dangerous URI schemes.
void launchUrlExternal(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
