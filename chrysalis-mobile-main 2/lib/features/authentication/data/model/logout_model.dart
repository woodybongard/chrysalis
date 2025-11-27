class LogoutRequestModel {
  LogoutRequestModel({required this.refreshToken});
  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
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
