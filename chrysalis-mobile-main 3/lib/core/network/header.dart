import 'dart:developer';

import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';

Future<Map<String, String>> getHeaders({
  bool isMultipart = false,
  bool includeDeviceId = false,
  String? deviceId,
}) async {
  final storage = LocalStorage();
  final token = await storage.read(key: AppKeys.accessToken) ?? '';

  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
  };

  if (token.isNotEmpty && !includeDeviceId) {
    log('Authorization token found, $token');
    headers['Authorization'] = 'Bearer $token';
  }

  if (includeDeviceId && deviceId != null) {
    headers['x-device-id'] = deviceId;
  }

  return headers;
}
