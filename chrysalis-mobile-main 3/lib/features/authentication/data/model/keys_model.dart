import 'package:chrysalis_mobile/features/authentication/domain/entity/key_entity.dart';

class KeysModel extends KeyEntity {
  const KeysModel({
    required super.deviceId,
    required super.hasKeys,
    required super.privateKey,
    required super.publicKey,
  });

  factory KeysModel.fromJson(Map<String, dynamic> json) {
    return KeysModel(
      deviceId: json['deviceId'] as String? ?? '',
      hasKeys: json['hasKeys'] as bool? ?? false,
      privateKey: json['privateKey'] as String? ?? '',
      publicKey: json['publicKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'hasKeys': hasKeys,
    'privateKey': privateKey,
    'publicKey': publicKey,
  };
}
