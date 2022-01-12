import 'dart:io';

import 'package:args/args.dart';
import 'services.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  // get the arguments
  ArgParser parser = ArgParser();
  ArgResults result = parser.parse(args);
  args = result.arguments;
  String? keysDirPath;
  Platform.script.path.endsWith('.exe')
      ? keysDirPath =
          path.join(Platform.script.path.split('atsign-helper.exe')[0], 'Keys')
      : keysDirPath = path.join(Platform.script.path.split('bin/')[0], 'Keys');
  Directory keysDir = Directory(
      Platform.isWindows ? keysDirPath.replaceFirst('/', '') : keysDirPath);
  if (!keysDir.existsSync()) {
    keysDir.createSync(recursive: true);
  }
  if (args.isEmpty) {
    await EncryptionUtil.getPkam(keysDir.path);
    exit(0);
  }
  if (args.length < 2 && args.isNotEmpty) {
    stderr.writeln('No such argument found.\n');
    stdout.writeln('Usage: atsign-helper.exe <args>');
    stdout.writeln('Arguments:');
    stdout.writeln('pkam-digest <@sign>  - Generates a PKAM digest');
    stdout.writeln('cram-digest <@sign>  - Generates a CRAM digest');
    stdout.writeln(
        'If no argumensts were passed, that mean you want to decrypt a PKAM key from @sign.atKeys file');
    exit(1);
  }
  final String program = args[0];
  switch (program) {
    case 'pkam-digest':
      if (args[1].isEmpty) {
        stderr.write('Please provide the pkam secret key file');
        exit(-1);
      }
      await EncryptionUtil.pkamDigest(keysDir.path, args[1]);
      break;
    case 'cram-digest':
      if (args[1].isEmpty) {
        stderr.write('Please provide the cram secret key file');
        exit(-1);
      }
      await EncryptionUtil.cramDigest(keysDir.path, args[1]);
      break;
    default:
      stderr.writeln('No such arguments found.\n');
      stdout.writeln('Usage: atsign-helper.exe <args>');
      stdout.writeln('Arguments:');
      stdout.writeln('pkam-digest <@sign>  - Generates a PKAM digest');
      stdout.writeln('cram-digest <@sign>  - Generates a CRAM digest');
      stdout.writeln(
          'If no argumensts were passed, that mean you want to decrypt a PKAM key from @sign.atKeys file');
      exit(-1);
  }
}
