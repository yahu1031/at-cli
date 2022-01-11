import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

class Copy {
  /// Get the contents from the clipboard.
  // static String getContents() {
  //   var dl = _loadLib();

  //   Pointer<Utf8> Function() _getContents = dl
  //       .lookup<NativeFunction<Pointer<Utf8> Function()>>('get_contents')
  //       .asFunction();

  //   return _getContents().toDartString();
  // }

  /// Set the contents of the clipboard.
  static void setContent(String contents) {
    var dl = _loadLib();

    void Function(Pointer<Utf8>) _setContents = dl
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('set_contents')
        .asFunction();

    var ptr = contents.toNativeUtf8();
    _setContents(ptr);
  }

  // Load the lib files to support the clipboard functionality
  static DynamicLibrary _loadLib() {
    var libPath = Platform.script.path.replaceAll(RegExp(r'[^/]+$'), '');
    String extension = Platform.isWindows
        ? 'dll'
        : Platform.isMacOS
            ? 'dylib'
            : 'so';
    if (Platform.isWindows) {
      if (libPath[0] == '/') libPath = libPath.replaceFirst('/', '');
    }
    libPath += 'lib/libclipboard.$extension';
    if (File(libPath).existsSync()) {
      return DynamicLibrary.open(libPath);
    } else {
      throw FileSystemException('libclipboard.$extension not found: $libPath');
    }
  }
}
