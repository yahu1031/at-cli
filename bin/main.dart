import 'dart:io';

import 'interactions/select_services.dart';
import 'services/services.dart';
// import 'package:path/path.dart' as path;

Future<void> main() async {
  Directory keysDir = Directory(Helpers.keysDirPath()!);
  if (!keysDir.existsSync()) {
    keysDir.createSync(recursive: true);
  }
  await Selectors.operation();
}
