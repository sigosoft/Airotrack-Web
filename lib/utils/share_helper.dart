import 'share_helper_stub.dart'
    if (dart.library.html) 'share_helper_web.dart' as platform;

void openShareUrl(String url) => platform.openExternalUrl(url);

Future<bool> invokeSystemShare({
  required String title,
  required String text,
  String? url,
}) =>
    platform.systemShare(title: title, text: text, url: url);
