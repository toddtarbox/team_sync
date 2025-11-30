// Stub implementation for non-web platforms
import 'dart:typed_data';

/// Stub function for mobile platforms (not used)
void downloadFile(Uint8List bytes, String filename) {
  // This should never be called on mobile
  throw UnsupportedError('Download not supported on this platform');
}
