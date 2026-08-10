import 'dart:convert';

import '../../../../core/database/database_helper.dart';
import 'backup_crypto_service.dart';
import 'backup_payload_migrator.dart';
import 'models/backup_envelope.dart';

class BackupRepositoryException implements Exception {
  final String message;

  const BackupRepositoryException(this.message);

  @override
  String toString() => message;
}

class BackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final BackupCryptoService _cryptoService;

  BackupRepository({BackupCryptoService? cryptoService})
      : _cryptoService = cryptoService ?? BackupCryptoService();

  Future<String> exportReadableJson({required String currencyCode}) async {
    final payload = await _buildPayload();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'PocketBudget',
      'backup_format_version': BackupEnvelope.currentFormatVersion,
      'backup_schema_version': BackupPayloadMigrator.currentSchemaVersion,
      'database_schema_version': DatabaseHelper.currentDatabaseVersion,
      'currency_code': currencyCode,
      'exported_at': DateTime.now().toIso8601String(),
      'encrypted': false,
      'restorable': false,
      'data': payload['data'],
    });
  }

  Future<String> exportEncryptedJson({
    required String currencyCode,
    required String password,
  }) async {
    final payload = await _buildPayload();
    final encrypted = await _cryptoService.encrypt(
      jsonEncode(payload),
      password,
      aad: _aad(
        currencyCode,
        DatabaseHelper.currentDatabaseVersion,
        BackupPayloadMigrator.currentSchemaVersion,
      ),
    );
    final envelope = BackupEnvelope(
      currencyCode: currencyCode,
      exportedAt: DateTime.now().toIso8601String(),
      backupSchemaVersion: BackupPayloadMigrator.currentSchemaVersion,
      databaseSchemaVersion: DatabaseHelper.currentDatabaseVersion,
      encryption: encrypted.toMap(),
      ciphertextBase64: encrypted.ciphertextBase64,
    );
    return const JsonEncoder.withIndent('  ').convert(envelope.toMap());
  }

  Future<void> restoreEncryptedJson(
    String jsonStr, {
    required String expectedCurrencyCode,
    required String password,
  }) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) throw const FormatException('Invalid backup JSON');
      final envelope =
          BackupEnvelope.fromMap(Map<String, dynamic>.from(decoded));
      if (envelope.currencyCode != expectedCurrencyCode) {
        throw const BackupRepositoryException('Backup currency does not match');
      }
      if (envelope.databaseSchemaVersion >
          DatabaseHelper.currentDatabaseVersion) {
        throw const BackupRepositoryException(
            'Backup database version is newer than this app');
      }
      final encryption = envelope.encryption;
      final encrypted = EncryptedBackupPayload(
        ciphertextBase64: envelope.ciphertextBase64,
        saltBase64: _stringField(encryption, 'salt_base64'),
        nonceBase64: _stringField(encryption, 'nonce_base64'),
        macBase64: _stringField(encryption, 'mac_base64'),
        iterations: encryption['iterations'] as int,
      );
      final payloadJson = await _cryptoService.decrypt(
        encrypted,
        password,
        aad: _aad(
          expectedCurrencyCode,
          envelope.databaseSchemaVersion,
          envelope.backupSchemaVersion,
        ),
      );
      final payload = jsonDecode(payloadJson);
      if (payload is! Map) {
        throw const FormatException('Invalid backup payload');
      }
      final normalized =
          BackupPayloadMigrator.normalize(Map<String, dynamic>.from(payload));
      final db = await _dbHelper.database;
      await db.transaction(
          (txn) => BackupPayloadMigrator.restoreData(txn, normalized));
    } on BackupRepositoryException {
      rethrow;
    } on BackupCryptoException catch (error) {
      throw BackupRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BackupRepositoryException(error.message);
    } catch (_) {
      throw const BackupRepositoryException('Backup could not be restored');
    }
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final db = await _dbHelper.database;
    return {
      'schema_version': BackupPayloadMigrator.currentSchemaVersion,
      'data': {
        'categories': await db.query('categories'),
        'transactions': await db.query('transactions'),
        'savings_goals': await db.query('savings_goals'),
        'savings_logs': await db.query('savings_logs'),
        'budget_allocations': await db.query('budget_allocations'),
        'budgets': await db.query('budgets'),
        'initial_balance': await db.query('initial_balance'),
      },
    };
  }

  List<int> _aad(
    String currencyCode,
    int databaseSchemaVersion,
    int backupSchemaVersion,
  ) => utf8.encode(
        'PocketBudget|${BackupEnvelope.currentFormatVersion}|'
        '$backupSchemaVersion|$databaseSchemaVersion|$currencyCode',
      );

  String _stringField(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String) {
      throw FormatException('Invalid encryption field: $key');
    }
    return value;
  }
}
