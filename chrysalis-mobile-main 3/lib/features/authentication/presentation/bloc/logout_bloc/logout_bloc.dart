import 'dart:developer';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/local_storage/chat_file_storage.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/logout_model.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/logout_usecase.dart';
import 'package:chrysalis_mobile/features/notifications/data/remote/notification_remote_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'logout_event.dart';
part 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  LogoutBloc(this.logoutUseCase) : super(LogoutInitial()) {
    on<LogoutRequested>(_onLogoutRequested);
  }
  final LogoutUseCase logoutUseCase;

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LogoutState> emit,
  ) async {
    log('[LogoutBloc] Logout requested - Starting logout process');
    emit(LogoutInProgress());
    
    try {
      log('[LogoutBloc] Reading refresh token from local storage');
      final refreshToken = await LocalStorage().read(key: AppKeys.refreshToken);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        log('[LogoutBloc] No refresh token found, clearing local storage and emitting success');
        await _clearLocalStorage();
        emit(LogoutSuccess());
        return;
      }
      
      log('[LogoutBloc] Refresh token found: ${refreshToken.substring(0, 10)}...');
      
      // Get FCM token - empty string for web, actual token for mobile
      log('[LogoutBloc] Platform check: kIsWeb = $kIsWeb');
      final notificationService = NotificationRemoteService();
      var fcmToken = '';
      
      if (!kIsWeb) {
        log('[LogoutBloc] Mobile platform - getting FCM token');
        final token = await notificationService.getToken();
        fcmToken = token ?? '';
        log('[LogoutBloc] FCM token retrieved: ${fcmToken.isNotEmpty ? "${fcmToken.substring(0, 10)}..." : "empty"}');
      } else {
        log('[LogoutBloc] Web platform - using empty FCM token');
      }
      
      final request = LogoutRequestModel(
        refreshToken: refreshToken,
        fcmToken: fcmToken,
      );
      
      log('[LogoutBloc] Calling logout use case with request data');
      log('[LogoutBloc] Request: refreshToken=${refreshToken.substring(0, 10)}..., fcmToken=${fcmToken.isEmpty ? "empty" : "${fcmToken.substring(0, 10)}..."}');
      
      await logoutUseCase(request);
      log('[LogoutBloc] Logout use case completed successfully');
      
      log('[LogoutBloc] Clearing local storage');
      await _clearLocalStorage();
      
      log('[LogoutBloc] Emitting LogoutSuccess');
      emit(LogoutSuccess());
    } catch (e) {
      log('[LogoutBloc] Error during logout: $e');
      log('[LogoutBloc] Clearing local storage due to error');
      await _clearLocalStorage();
      log('[LogoutBloc] Emitting LogoutFailure with message: ${e.toString()}');
      emit(LogoutFailure(e.toString()));
    }
  }

  Future<void> _clearLocalStorage() async {
    await LocalStorage().clear();
    // Skip file storage clearing on web platform as it's not supported
    if (!kIsWeb) {
      await ChatFileStorage().clearAll();
    }
  }
}
