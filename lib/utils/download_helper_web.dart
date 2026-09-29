// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

void downloadFileFromBytes(
  List<int> bytes,
  String fileName,
  String mimeType,
) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadCsvString(String csvContent, String fileName) {
  // Prepend UTF-8 Byte Order Mark (BOM) so Microsoft Excel opens it cleanly
  final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
  downloadFileFromBytes(bytes, fileName, 'text/csv;charset=utf-8');
}
