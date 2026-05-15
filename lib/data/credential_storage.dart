import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:resumate/models/deployment.dart';

class CredentialStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(PlatformCredentials creds) async {
    final key = await _key();
    final encrypted = _encrypt(jsonEncode(creds.toJson()), key);
    await _storage.write(key: 'creds_${creds.platform}', value: encrypted);
  }

  Future<PlatformCredentials?> load(String platform) async {
    final encrypted = await _storage.read(key: 'creds_$platform');
    if (encrypted == null) return null;
    final key = await _key();
    final json = jsonDecode(_decrypt(encrypted, key)) as Map<String, dynamic>;
    return PlatformCredentials.fromJson(json);
  }

  Future<void> delete(String platform) async =>
      _storage.delete(key: 'creds_$platform');

  Future<List<String>> storedPlatforms() async {
    final all = await _storage.readAll();
    return all.keys.where((k) => k.startsWith('creds_')).map((k) => k.substring(6)).toList();
  }

  Future<String> _key() async {
    var k = await _storage.read(key: 'master_key');
    if (k == null) {
      k = enc.Key.fromSecureRandom(32).base64;
      await _storage.write(key: 'master_key', value: k);
    }
    return k;
  }

  String _encrypt(String plain, String keyB64) {
    final key = enc.Key.fromBase64(keyB64);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = enc.Encrypter(enc.AES(key)).encrypt(plain, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String _decrypt(String cipher, String keyB64) {
    final parts = cipher.split(':');
    final iv = enc.IV.fromBase64(parts[0]);
    final key = enc.Key.fromBase64(keyB64);
    return enc.Encrypter(enc.AES(key)).decrypt64(parts[1], iv: iv);
  }
}
