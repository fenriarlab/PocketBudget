import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/backup/data/backup_crypto_service.dart';

void main() {
  test('encrypts and decrypts with AES-256-GCM', () async {
    final service = BackupCryptoService();
    final encrypted = await service.encrypt(
      '{"amount":42}',
      'correct horse battery staple',
      aad: utf8.encode('metadata'),
    );

    expect(encrypted.iterations, greaterThanOrEqualTo(100000));
    expect(encrypted.saltBase64, isNotEmpty);
    expect(encrypted.nonceBase64, isNotEmpty);
    expect(
      await service.decrypt(
        encrypted,
        'correct horse battery staple',
        aad: utf8.encode('metadata'),
      ),
      '{"amount":42}',
    );
  });

  test('rejects a wrong password and changed authenticated metadata', () async {
    final service = BackupCryptoService();
    final encrypted = await service.encrypt(
      'private data',
      'correct horse battery staple',
      aad: utf8.encode('metadata'),
    );

    await expectLater(
      service.decrypt(encrypted, 'wrong password',
          aad: utf8.encode('metadata')),
      throwsA(isA<BackupCryptoException>()),
    );
    await expectLater(
      service.decrypt(encrypted, 'correct horse battery staple',
          aad: utf8.encode('changed')),
      throwsA(isA<BackupCryptoException>()),
    );
  });
}
