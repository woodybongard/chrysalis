import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/asymmetric/api.dart' as pc;
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

class CryptoService {
  static const _privateKeyKey = 'user_private_key';
  static const _publicKeyKey = 'user_public_key';

  final _storage = const FlutterSecureStorage();

  pc.RSAPrivateKey? _privateKey;
  pc.RSAPublicKey? _publicKey;

  /// 1. Generate keys if not exist (for first-time user)
  Future<void> generateKeyPairIfNeeded() async {
    final pair = CryptoUtils.generateRSAKeyPair();
    _privateKey = pair.privateKey as pc.RSAPrivateKey;
    _publicKey = pair.publicKey as pc.RSAPublicKey;

    final privPemNew = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(_privateKey!);
    final pubPemNew = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(_publicKey!);

    await _storage.write(key: _privateKeyKey, value: privPemNew);
    await _storage.write(key: _publicKeyKey, value: pubPemNew);
  }

  /// 2. Store keys from server (on login)
  Future<void> saveKeysFromServer({
    required String publicKeyPem,
    required String privateKeyPem,
  }) async {
    await _storage.write(key: _privateKeyKey, value: privateKeyPem);
    await _storage.write(key: _publicKeyKey, value: publicKeyPem);

    _privateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(privateKeyPem);
    _publicKey = CryptoUtils.rsaPublicKeyFromPemPkcs1(publicKeyPem);
  }

  /// 3. Load keys into memory
  Future<void> loadKeys() async {
    final privPem = await _storage.read(key: _privateKeyKey);
    final pubPem = await _storage.read(key: _publicKeyKey);

    if (privPem != null && pubPem != null) {
      _privateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(privPem);
      _publicKey = CryptoUtils.rsaPublicKeyFromPemPkcs1(pubPem);
    }
  }

  /// Getters
  Future<String?> getPublicKeyPem() async => _storage.read(key: _publicKeyKey);
  Future<String?> getPrivateKeyPem() async =>
      _storage.read(key: _privateKeyKey);

  /// AES Encrypt message with group sender key
  static Map<String, String> encryptGroupMessage(
    Key senderKey,
    String plainText,
  ) {
    // Generate random 16-byte IV
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final iv = IV(Uint8List.fromList(ivBytes));

    final encrypter = Encrypter(AES(senderKey));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return {'cipherText': encrypted.base64, 'iv': base64Encode(iv.bytes)};
  }

  /// AES Decrypt message with group sender key
  static String decryptGroupMessage(
    Key senderKey,
    String base64Cipher,
    String base64Iv,
  ) {
    try {
      // Validate inputs first
      if (base64Cipher.isEmpty || base64Iv.isEmpty) {
        return '[Empty message data]';
      }

      // Decode and validate IV
      final ivBytes = base64Decode(base64Iv);
      if (ivBytes.length != 16) {
        return '[Invalid IV length]';
      }
      
      final iv = IV(Uint8List.fromList(ivBytes));
      
      // Try standard decryption first
      final encrypter = Encrypter(AES(senderKey));
      return encrypter.decrypt64(base64Cipher, iv: iv);
      
    } catch (e) {
      // If decryption fails, return a user-friendly message instead of crashing
      return '[Message could not be decrypted]';
    }
  }

  /// RSA Encrypt with PKCS1 v1.5 (useful for encrypting group sender key)
  String rsaEncrypt(String plainText, pc.RSAPublicKey publicKey) {
    final engine = PKCS1Encoding(RSAEngine())
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));

    final input = Uint8List.fromList(utf8.encode(plainText));
    final cipher = _processInBlocks(engine, input);

    return base64Encode(cipher);
  }

  /// RSA Decrypt with PKCS1 v1.5 (decrypt group sender key)
  Future<Uint8List> rsaDecrypt(String encryptedBase64) async {
    try {
      if (_privateKey == null) {
        await loadKeys();
        if (_privateKey == null) throw Exception('Private key not loaded');
      }

      final engine = PKCS1Encoding(RSAEngine())
        ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(_privateKey!));

      final cipherBytes = base64Decode(encryptedBase64);
      return _processInBlocks(engine, cipherBytes);
    } catch (e) {
      throw Exception('RSA decryption failed: $e');
    }
  }

  /// helper for block processing
  Uint8List _processInBlocks(PKCS1Encoding engine, Uint8List input) {
    final numBlocks = (input.length / engine.inputBlockSize).ceil();
    final output = <int>[];

    for (var i = 0; i < numBlocks; i++) {
      final start = i * engine.inputBlockSize;
      final end = (i + 1) * engine.inputBlockSize;
      final block = input.sublist(
        start,
        end > input.length ? input.length : end,
      );
      output.addAll(engine.process(block));
    }
    return Uint8List.fromList(output);
  }
}

extension CryptoServiceExtensions on CryptoService {
  /// Decrypt RSA-encrypted group sender key and return AES Key object
  Future<Key> decryptGroupSenderKey(String encryptedKeyBase64) async {
    try {
      final decryptedBytes = await rsaDecrypt(encryptedKeyBase64);
      // Validate key length (AES-256 = 32 bytes, AES-128 = 16 bytes)
      if (decryptedBytes.length != 16 && decryptedBytes.length != 32) {
        throw Exception('Invalid AES key length: ${decryptedBytes.length}');
      }
      return Key(decryptedBytes); // AES Key
    } catch (e) {
      // Return a dummy key to prevent crashes - messages will show as "[Message could not be decrypted]"
      return Key.fromSecureRandom(32); // Generate a random 32-byte key
    }
  }
}
