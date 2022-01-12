import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

class Copy {

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
    var libPath = Platform.script.path.endsWith('.exe')
        ? Platform.script.path.split('atsign-helper.exe')[0]
        : Platform.script.path
            .split('bin/')[0]
            .replaceAll(RegExp(r'[^/]+$'), '');
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
