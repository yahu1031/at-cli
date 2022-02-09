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
    List<String> scriptPathSegments = Platform.script.pathSegments;
    if (scriptPathSegments.last.endsWith('.dart')) {
      libPath = path.joinAll(
          scriptPathSegments.sublist(0, scriptPathSegments.length - 2));
    } else if (scriptPathSegments.last.contains('at-helper')) {
      libPath = path.joinAll(
          scriptPathSegments.sublist(0, scriptPathSegments.length - 1));
    }
    String extension = Platform.isWindows
        ? 'dll'
        : Platform.isMacOS
            ? 'dylib'
            : 'so';

    String libFilePath = path.join(libPath, 'lib', 'libclipboard.$extension');
    if (File(libFilePath).existsSync()) {
      return DynamicLibrary.open(libFilePath);
    } else {
      throw FileSystemException(
          'libclipboard.$extension not found: $libFilePath');
    }
  }
}
