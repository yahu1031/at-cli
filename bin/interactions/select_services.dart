import 'dart:io';
import 'package:interact/interact.dart';

import 'input_services.dart';

/// Class of selectable options.
class Selectors {
  /// Selector for file overwriting.
  static String fileAlreadyExists(String path) {
    if (File(path).existsSync()) {
      int overwrite = Select(
        prompt:
            'Looks like file ${path.split('/').last} already exists. Do you want to overwrite it?',
        options: <String>['Yes', 'No'],
      ).interact();
      if (overwrite == 1) {
        String _path = path + '_new';
        return fileAlreadyExists(_path);
      }
    }
    return path;
  }

  /// Choose an operation to perform.
  static Future<void> operation() async {
    int operation = Select(
      prompt: 'What do you want help with?',
      options: <String>[
        'Get pkam secret',
        'pkam digest',
        'cram digest',
        'Get secondary location',
        'Exit'
      ],
    ).interact();
    switch (operation) {
      case 0:
        Inputs.getPKAM();
        break;
      case 1:
        Inputs.pkamDigest();
        break;
      case 2:
        Inputs.cramDigest();
        break;
      case 3:
        await Inputs.getSecondaryLocation();
        break;
      case 4:
        exit(0);
    }
  }
}
