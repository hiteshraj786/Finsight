import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local application-lock PIN. It is not an authentication credential and is
/// only available after Supabase has established a valid user session.
class PinService {
  static const _pinHashKey = 'user_security_pin_hash_v2';
  static const _pinSaltKey = 'user_security_pin_salt_v2';
  static const _attemptsKey = 'pin_failed_attempts';
  static const _lockedUntilKey = 'pin_locked_until';
  static const _maximumAttempts = 5;
  static const _lockout = Duration(minutes: 5);
  static const _storage = FlutterSecureStorage();

  static Future<bool> setPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return false;
    final salt = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final encodedSalt = base64UrlEncode(salt);
    final hash = _hash(pin, encodedSalt);
    await _storage.write(key: _pinSaltKey, value: encodedSalt);
    await _storage.write(key: _pinHashKey, value: hash);
    await _resetFailures();
    return true;
  }

  static Future<bool> verifyPin(String enteredPin) async {
    if (await isLocked()) return false;
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    final valid =
        salt != null &&
        storedHash != null &&
        _hash(enteredPin, salt) == storedHash;
    if (valid) {
      await _resetFailures();
    } else {
      await _recordFailure();
    }
    return valid;
  }

  static Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinHashKey);
      return pin != null && pin.isNotEmpty;
    } catch (_) {
      // A platform secure-storage failure must not unlock the app.
      return false;
    }
  }

  static Future<bool> isLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = prefs.getInt(_lockedUntilKey);
    if (lockedUntil == null) return false;
    if (DateTime.now().millisecondsSinceEpoch >= lockedUntil) {
      await _resetFailures();
      return false;
    }
    return true;
  }

  static Future<Duration?> lockoutRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = prefs.getInt(_lockedUntilKey);
    if (lockedUntil == null) return null;
    final milliseconds = lockedUntil - DateTime.now().millisecondsSinceEpoch;
    return milliseconds > 0 ? Duration(milliseconds: milliseconds) : null;
  }

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static Future<void> _recordFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final failures = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    if (failures >= _maximumAttempts) {
      await prefs.setInt(
        _lockedUntilKey,
        DateTime.now().add(_lockout).millisecondsSinceEpoch,
      );
      await prefs.setInt(_attemptsKey, 0);
    } else {
      await prefs.setInt(_attemptsKey, failures);
    }
  }

  static Future<void> _resetFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockedUntilKey);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _resetFailures();
  }
}
