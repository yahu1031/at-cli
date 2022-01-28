import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;

/// Helper class which provides functions to help other functionalities.
class Helpers {
  /// Returns the Keys directory.
  static String? keysDirPath() => Platform.isWindows
      ? path.join(Platform.environment['USERPROFILE']!, 'Keys')
      : path.join('/Users', Platform.environment['USER']!, 'Keys');

  /// Remove the first and last **`'`** from the path and return the path
  static String fixThePath(String path) =>
      (path.startsWith("'") && path.endsWith("'"))
          ? path.substring(1, path.length - 1)
          : path;

  /// Decrypt the given [encryptedValue] string using the [decryptionKey]
  static String decryptValue(String encryptedValue, String decryptionKey) =>
      Encrypter(AES(Key.fromBase64(decryptionKey)))
          .decrypt64(encryptedValue, iv: IV.fromLength(16));
}
