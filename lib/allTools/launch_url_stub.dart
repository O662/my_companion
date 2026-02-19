import 'package:url_launcher/url_launcher.dart';

/// Mobile implementation using url_launcher package.
void launchUrlExternal(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
