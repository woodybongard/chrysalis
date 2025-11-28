class KeyEntity {
  const KeyEntity({
    required this.deviceId,
    required this.hasKeys,
    required this.privateKey,
    required this.publicKey,
  });
  final String deviceId;
  final String publicKey;
  final String privateKey;
  final bool hasKeys;
}
