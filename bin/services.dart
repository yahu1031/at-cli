import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';

import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

import 'copy.dart';

class EncryptionUtil {
  static String decryptValue(String encryptedValue, String decryptionKey) {
    var aesKey = AES(Key.fromBase64(decryptionKey));
    var decrypter = Encrypter(aesKey);
    var iv2 = IV.fromLength(16);
    return decrypter.decrypt64(encryptedValue, iv: iv2);
  }

  static Future<void> cramDigest(String keysDirPath, String atSign) async {
    String cramSecretFile = path.join(keysDirPath, atSign);
    File cramFile = File(cramSecretFile);
    if (!cramFile.existsSync()) {
      stderr.write('Cram file not found: $cramSecretFile');
      exit(-1);
    }
    String cramContent = await cramFile.readAsString();
    cramContent = cramContent.trim();
    stdout.writeln('Please provide challenge');
    String? challenge = stdin.readLineSync();
    if (challenge!.contains('data')) {
      challenge = challenge.split('data:')[1];
    }
    challenge = challenge.trim();
    String combo = "$cramContent$challenge";
    var bytes = utf8.encode(combo);
    var digest = sha512.convert(bytes);
    stdout.writeln(
        'PKAM challange result was copied to your clipboard. Just paste it in the terminal.');
    Copy.setContent('cram:$digest');
    exit(0);
  }

  static Future<void> getPkam(String keysDir) async {
    stdout.writeln('Please enter the path of your key file');
    // take user input
    String? keyPath = stdin.readLineSync();
    if (keyPath == null) {
      stderr.write('\nPlease enter a valid path');
      exit(-1);
    }
    if (keyPath.startsWith('\'') && keyPath.endsWith('\'')) {
      keyPath = keyPath.substring(1, keyPath.length - 1);
    }
    File keysFile = File(keyPath);
    if (!keysFile.existsSync()) {
      stderr.write('\nSorry. File does not exist');
      exit(-1);
    }
    // read the file
    String keys = await keysFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(keys);
    String atSign = jsonData.keys.last;
    String? aesPkamPrivateKey = jsonData['aesPkamPrivateKey'];
    String? selfEncryptionKey = jsonData['selfEncryptionKey'];
    if (aesPkamPrivateKey == null || selfEncryptionKey == null) {
      stderr.write('\nSorry. File does not contain the required keys');
      exit(-1);
    }
    String pkamKey =
        EncryptionUtil.decryptValue(aesPkamPrivateKey, selfEncryptionKey);
    if (atSign.startsWith('@')) {
      File pkamFile = File(path.join(keysDir, atSign));
      if (await pkamFile.exists()) {
        stdout.writeln(
            '$atSign file already exists in $keysDir. Do you want to overwrite it?(y/n)');
        String? option = stdin.readLineSync();
        if (option == null || option.toLowerCase() != 'y') {
          stdout.writeln('\n\n');
          stdout.writeln(pkamKey);
          exit(0);
        } else {
          await pkamFile.writeAsString(pkamKey);
          stdout
              .writeln('\nYour file has been saved as $atSign in Keys folder');
          exit(0);
        }
      }
    } else {
      stdout.writeln(pkamKey);
      exit(0);
    }
  }

  static Future<void> pkamDigest(String keysDirPath, String atSign) async {
    String pkamSecretFile = path.join(keysDirPath, atSign);
    File pkamFile = File(pkamSecretFile);
    if (!pkamFile.existsSync()) {
      stderr.write('Pkam file not found: $pkamFile');
      exit(-1);
    }
    String cramContent = await pkamFile.readAsString();
    cramContent = cramContent.trim();
    RSAPrivateKey key = RSAPrivateKey.fromString(cramContent);
    stdout.writeln('Please provide challenge');
    String? challenge = stdin.readLineSync();
    if (challenge == null) {
      stderr.write('\nPlease enter a valid challenge');
      exit(-1);
    }
    if (challenge.contains('data')) {
      challenge = challenge.split('data:')[1];
    }
    if (challenge.contains('data')) {
      challenge = challenge.split('data:')[1];
    }
    challenge = challenge.trim();
    var bytes = utf8.encode(challenge);
    var shaSignature = key.createSHA256Signature(bytes as Uint8List);
    var signature = base64.encode(shaSignature);
    stdout.writeln(
        'CRAM challange result was copied to your clipboard. Just paste it in the terminal.');
    Copy.setContent('cram:$signature');

    stdout.write('\n');
    exit(0);
  }
}
