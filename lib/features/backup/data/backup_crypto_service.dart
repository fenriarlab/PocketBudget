import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class BackupCryptoException implements Exception {
  final String message;

  const BackupCryptoException(this.message);

  @override
  String toString() => message;
}

class EncryptedBackupPayload {
  final String ciphertextBase64;
  final String saltBase64;
  final String nonceBase64;
  final String macBase64;
  final int iterations;

  const EncryptedBackupPayload({
    required this.ciphertextBase64,
    required this.saltBase64,
    required this.nonceBase64,
    required this.macBase64,
    required this.iterations,
  });

  Map<String, dynamic> toMap() => {
        'algorithm': 'AES-256-GCM',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': iterations,
        'salt_base64': saltBase64,
        'nonce_base64': nonceBase64,
        'mac_base64': macBase64,
      };
}

class BackupCryptoService {
  static const int iterations = 100000;
  static const int saltLength = 16;
  static const int nonceLength = 12;

  final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );
  final AesGcm _cipher = AesGcm.with256bits();

  Future<EncryptedBackupPayload> encrypt(
    String plainText,
    String password, {
    List<int> aad = const [],
  }) async {
    _validatePassword(password);
    final random = Random.secure();
    final salt = List<int>.generate(saltLength, (_) => random.nextInt(256));
    final nonce = List<int>.generate(nonceLength, (_) => random.nextInt(256));
    final key = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final box = await _cipher.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    return EncryptedBackupPayload(
      ciphertextBase64: base64Encode(box.cipherText),
      saltBase64: base64Encode(salt),
      nonceBase64: base64Encode(box.nonce),
      macBase64: base64Encode(box.mac.bytes),
      iterations: iterations,
    );
  }

  Future<String> decrypt(
    EncryptedBackupPayload payload,
    String password, {
    List<int> aad = const [],
  }) async {
    _validatePassword(password);
    if (payload.iterations != iterations) {
      throw const BackupCryptoException('Unsupported key derivation settings');
    }
    try {
      final salt = base64Decode(payload.saltBase64);
      final nonce = base64Decode(payload.nonceBase64);
      final ciphertext = base64Decode(payload.ciphertextBase64);
      final mac = base64Decode(payload.macBase64);
      final key = await _kdf.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      final box = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(mac),
      );
      final clearText = await _cipher.decrypt(box, secretKey: key, aad: aad);
      return utf8.decode(clearText);
    } catch (_) {
      throw const BackupCryptoException(
          'Backup password or contents are invalid');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const BackupCryptoException(
          'Backup password must be at least 8 characters');
    }
  }
}
