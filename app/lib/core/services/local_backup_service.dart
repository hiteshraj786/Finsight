import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/sms/data/database.dart';

class LocalBackupService {
  LocalBackupService._();

  static const _keyName = 'finsight_local_backup_key_v1';
  static const _storage = FlutterSecureStorage();

  static Future<void> shareEncryptedBackup() async {
    final key = await _loadOrCreateKey();
    final database = AppDatabase.instance;
    final payload = {
      'version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'tables': {
        'transactions': await _rows(database, 'transactions'),
        'merchant_rules': await _rows(database, 'merchant_rules'),
        'app_states': await _rows(database, 'app_states'),
        'custom_categories': await _rows(database, 'custom_categories'),
      },
    };
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromBase64(key), mode: encrypt.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(jsonEncode(payload), iv: iv);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}finsight-backup-${DateTime.now().toUtc().millisecondsSinceEpoch}.finsight',
    );
    await file.writeAsString(
      jsonEncode({
        'format': 'finsight-encrypted-backup-v1',
        'iv': iv.base64,
        'ciphertext': encrypted.base64,
      }),
      flush: true,
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'FinSight encrypted backup',
    );
  }

  static Future<String> _loadOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) return existing;
    final key = encrypt.Key.fromSecureRandom(32).base64;
    await _storage.write(key: _keyName, value: key);
    return key;
  }

  static Future<List<Map<String, dynamic>>> _rows(
    AppDatabase database,
    String table,
  ) async {
    final rows = await database.customSelect('SELECT * FROM $table').get();
    return rows.map((row) {
      final output = <String, dynamic>{};
      for (final entry in row.data.entries) {
        output[entry.key] = _jsonValue(entry.value);
      }
      return output;
    }).toList();
  }

  static Object? _jsonValue(Object? value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is List<int>) return base64Encode(value);
    return value;
  }
}
