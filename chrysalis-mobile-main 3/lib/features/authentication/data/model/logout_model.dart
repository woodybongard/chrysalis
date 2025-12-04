class LogoutRequestModel {
  LogoutRequestModel({
    required this.refreshToken,
    required this.fcmToken,
  });
  final String refreshToken;
  final String fcmToken;

  Map<String, dynamic> toJson() => {
    'refreshToken': refreshToken,
    'fcmToken': fcmToken,
  };
}

class LogoutResponseModel {
  LogoutResponseModel({required this.success, required this.message});

  factory LogoutResponseModel.fromJson(Map<String, dynamic> json) {
    return LogoutResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
  final bool success;
  final String message;
}
