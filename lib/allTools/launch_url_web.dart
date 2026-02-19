import 'dart:html' as html;

/// Web implementation: opens a URL in a new browser tab.
void launchUrlExternal(String url) {
  html.window.open(url, '_blank');
}
