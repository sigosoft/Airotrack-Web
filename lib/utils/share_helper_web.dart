// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openExternalUrl(String url) {
  html.window.open(url, '_blank');
}

Future<bool> systemShare({
  required String title,
  required String text,
  String? url,
}) async {
  try {
    if (html.window.navigator.share != null) {
      final shareData = <String, dynamic>{
        'title': title,
        'text': text,
        if (url != null) 'url': url,
      };
      await html.window.navigator.share(shareData);
      return true;
    }
  } catch (e) {
    // Share cancelled or not supported
  }
  return false;
}
