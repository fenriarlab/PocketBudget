class BackupEnvelope {
  static const int currentFormatVersion = 1;
  static const int currentSchemaVersion = 2;

  final String currencyCode;
  final String exportedAt;
  final int backupSchemaVersion;
  final int databaseSchemaVersion;
  final Map<String, dynamic> encryption;
  final String ciphertextBase64;

  const BackupEnvelope({
    required this.currencyCode,
    required this.exportedAt,
    required this.backupSchemaVersion,
    required this.databaseSchemaVersion,
    required this.encryption,
    required this.ciphertextBase64,
  });

  Map<String, dynamic> toMap() => {
        'app': 'PocketBudget',
        'backup_format_version': currentFormatVersion,
        'backup_schema_version': backupSchemaVersion,
        'database_schema_version': databaseSchemaVersion,
        'currency_code': currencyCode,
        'exported_at': exportedAt,
        'encryption': encryption,
        'ciphertext_base64': ciphertextBase64,
      };

  static BackupEnvelope fromMap(Map<String, dynamic> map) {
    if (map['app'] != 'PocketBudget' ||
        map['backup_format_version'] != currentFormatVersion ||
        (map['backup_schema_version'] != 1 &&
            map['backup_schema_version'] != currentSchemaVersion)) {
      throw const FormatException('Unsupported backup format');
    }
    final currencyCode = map['currency_code'];
    final exportedAt = map['exported_at'];
    final backupSchemaVersion = map['backup_schema_version'];
    final databaseSchemaVersion = map['database_schema_version'];
    final encryption = map['encryption'];
    final ciphertext = map['ciphertext_base64'];
    if (currencyCode is! String ||
        exportedAt is! String ||
        backupSchemaVersion is! int ||
        databaseSchemaVersion is! int ||
        encryption is! Map ||
        ciphertext is! String) {
      throw const FormatException('Invalid encrypted backup envelope');
    }
    return BackupEnvelope(
      currencyCode: currencyCode,
      exportedAt: exportedAt,
      backupSchemaVersion: backupSchemaVersion,
      databaseSchemaVersion: databaseSchemaVersion,
      encryption: Map<String, dynamic>.from(encryption),
      ciphertextBase64: ciphertext,
    );
  }
}
