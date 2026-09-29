import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as platform;

void downloadCsv(String csvContent, String fileName) =>
    platform.downloadCsvString(csvContent, fileName);

void downloadBytes(List<int> bytes, String fileName, String mimeType) =>
    platform.downloadFileFromBytes(bytes, fileName, mimeType);
