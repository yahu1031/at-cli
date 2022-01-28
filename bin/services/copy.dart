import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

/// Copy class
class Copy {
  /// Set the contents of the clipboard.
  static void setContent(String contents) {
    DynamicLibrary dl = _loadLib();

    void Function(Pointer<Utf8>) _setContents = dl
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('set_contents')
        .asFunction();

    Pointer<Utf8> ptr = contents.toNativeUtf8();
    _setContents(ptr);
  }

  /// Load the lib files to support the clipboard functionality
  static DynamicLibrary _loadLib() {
    late String libPath;
    String scriptPath = Platform.script.path;
    if (scriptPath.split('/').last.endsWith('.dart')) {
      libPath = Platform.script.path.split('/bin/')[0];
    } else if (scriptPath.split('/').last.contains('atsign-helper')) {
      libPath = Platform.script.path.split('atsign-helper')[0];
    }
    libPath = Platform.isWindows
        ? libPath.replaceFirst('/', '').replaceAll('/', '\\')
        : libPath;
    String extension = Platform.isWindows
        ? 'dll'
        : Platform.isMacOS
            ? 'dylib'
            : 'so';
    // if (Platform.isWindows) {
    //   if (libPath[0] == '/') libPath = libPath.replaceFirst('/', '');
    // }
    libPath = path.join(libPath, 'lib', 'libclipboard.$extension');
    if (File(libPath).existsSync()) {
      return DynamicLibrary.open(libPath);
    } else {
      throw FileSystemException('libclipboard.$extension not found: $libPath');
    }
  }
}
