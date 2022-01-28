import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:tint/tint.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:crypto/src/digest.dart';
import 'package:crypton/crypton.dart';
import 'package:crypto/src/sha512.dart';
import 'package:interact/interact.dart';
import 'package:path/path.dart' as path;
import '../services/copy.dart';
import '../services/services.dart';
import 'select_services.dart';

/// Class of input interactives
class Inputs {
  /// Get pkam secret from the file user passed.
  static void getPKAM() {
    String projectDirectory = Input(
      prompt: 'Please enter the path of your key file : ',
      defaultValue: 'your atKeys path',
      validator: (String x) {
        if (File(Helpers.fixThePath(x)).existsSync()) {
          return true;
        } else {
          throw ValidationError('${Helpers.fixThePath(x)} is not a valid path');
        }
      },
    ).interact();
    projectDirectory = Helpers.fixThePath(projectDirectory);
    File keysFile = File(projectDirectory);
    String? keyFileName = getFileName();
    String keys = keysFile.readAsStringSync();
    Map<String, dynamic> jsonData = jsonDecode(keys);
    String atSign = jsonData.keys.last;
    if (keyFileName == null || keyFileName.isEmpty) {
      keyFileName = atSign;
    }
    String? aesPkamPrivateKey = jsonData['aesPkamPrivateKey'];
    String? selfEncryptionKey = jsonData['selfEncryptionKey'];
    if (aesPkamPrivateKey == null || selfEncryptionKey == null) {
      stderr.writeln('Sorry. File does not contain the required keys');
      exit(-1);
    }
    String pkamKey = Helpers.decryptValue(aesPkamPrivateKey, selfEncryptionKey);
    String? keysPath = Helpers.keysDirPath();
    if (keysPath == null) {
      stderr.writeln('Sorry. Could not find the keys directory');
      exit(-1);
    }
    String pkamFilePath = path.join(keysPath, keyFileName);
    pkamFilePath = Selectors.fileAlreadyExists(pkamFilePath);
    File(pkamFilePath).writeAsStringSync(pkamKey);
    stdout.writeln(
        'Your file has been saved as ${pkamFilePath.split('/').last} in $pkamFilePath');
    sleep(const Duration(seconds: 3));
    exit(0);
  }

  /// Get the file name from the user.
  static String? getFileName() => Input(
        prompt:
            'What you would like to name the file to be stored as (Default name is your @sign) : ',
        defaultValue: null,
        validator: (String x) {
          if (x.split('.').length > 1) {
            throw ValidationError('Better not to include extensions or `.`');
          } else {
            return true;
          }
        },
      ).interact();

  /// Make a PKAM digest and copy it to the clipboard.
  static void pkamDigest() {
    String? keysDir = Helpers.keysDirPath();
    String? pkamSecretFileName = Input(
      prompt: 'Please enter your @sign secret filename : ',
      defaultValue: null,
      validator: (String x) {
        if (keysDir == null) {
          throw ValidationError('Sorry. Could not find the keys directory');
        }
        if (!File(path.join(keysDir, x)).existsSync()) {
          throw ValidationError('Looks like your secret file does not exist');
        } else {
          return true;
        }
      },
    ).interact();
    File pkamFile = File(path.join(keysDir!, pkamSecretFileName));
    stdout.write(
        '${'?'.yellow().blink()} Please provide PKAM challenge : '.bold());
    String? challenge = stdin.readLineSync()?.trim();
    if (challenge == null || challenge.isEmpty) {
      stderr.write('Looks like you forgot to enter a challenge'.red().bold());
      exit(0);
    }
    if (challenge.startsWith('data:') && challenge.length < 90) {
      stderr.write('Sorry. That is not a valid challenge'.red().bold());
      exit(0);
    }
    String pkamContent = pkamFile.readAsStringSync().trim();
    RSAPrivateKey key = RSAPrivateKey.fromString(pkamContent);
    if (challenge.startsWith('data:')) {
      challenge = challenge.split('data:')[1].trim();
    }
    challenge = challenge.trim();
    Uint8List shaSignature =
        key.createSHA256Signature(utf8.encode(challenge) as Uint8List);
    String signature = base64.encode(shaSignature);
    stdout.writeln('PKAM challange result was copied to your clipboard. ' +
        'Just paste it in the terminal.'.blink().green());
    Copy.setContent('pkam:$signature');
    sleep(const Duration(seconds: 3));
    exit(0);
  }

  /// Make a CRAM digest and copy it to the clipboard.
  static void cramDigest() {
    String? keysDir = Helpers.keysDirPath();
    String? cramSecretFileName = Input(
      prompt: 'Please enter your @sign secret filename : ',
      defaultValue: null,
      validator: (String x) {
        if (keysDir == null) {
          throw ValidationError('Sorry. Could not find the keys directory');
        }
        if (!File(path.join(keysDir, x)).existsSync()) {
          throw ValidationError('Looks like your secret file does not exist');
        } else {
          return true;
        }
      },
    ).interact();
    File cramFile = File(path.join(keysDir!, cramSecretFileName));
    stdout.write(
        '${'?'.yellow().blink()} Please provide CRAM challenge : '.bold());
    String? challenge = stdin.readLineSync();
    if (challenge == null || challenge.isEmpty) {
      stderr.writeln('Looks like you forgot to enter a challenge'.red().bold());
      exit(0);
    }
    if (challenge.startsWith('data:') && challenge.length < 90) {
      stderr.writeln('Sorry. That is not a valid challenge'.red().bold());
      exit(0);
    }
    String cramContent = cramFile.readAsStringSync().trim();
    if (challenge.startsWith('data:')) {
      challenge = challenge.split('data:')[1].trim();
    }
    challenge = challenge.trim();
    String cramCombo = cramContent + challenge;
    List<int> bytes = utf8.encode(cramCombo);
    Digest cramDigestContent = sha512.convert(bytes);
    stdout.writeln('CRAM challange result was copied to your clipboard. ' +
        'Just paste it in the terminal.'.blink().green());
    Copy.setContent('cram:$cramDigestContent');
    sleep(const Duration(seconds: 3));
    exit(0);
  }

  static Future<void> getSecondaryLocation() async {
    String atSign = Input(
      prompt: 'Please enter your @sign : ',
      defaultValue: null,
      validator: (String x) {
        if (x.isEmpty) {
          throw ValidationError('Looks like you forgot to enter your @sign');
        } else {
          return true;
        }
      },
    ).interact();
    SpinnerState spinner = Spinner(
      icon: '🔍',
      rightPrompt: (_) => 'searching $atSign secondary location...',
    ).interact();
    AtStatus status = await AtStatusImpl().get(atSign);
    spinner.done();
    stdout.writeln(status.serverLocation == null
        ? 'Sorry. Could not find your @sign location'.yellow().bold()
        : 'Your @sign location is ${status.serverLocation?.green().bold().blink()}');
    exit(0);
  }
}
