import 'dart:typed_data';

import 'download_utils_io.dart' if (dart.library.html) 'download_utils_web.dart' as impl;

Future<bool> downloadFile(String filename, Uint8List bytes, {String mimeType = 'application/octet-stream'}) {
  return impl.downloadFile(filename, bytes, mimeType: mimeType);
}
