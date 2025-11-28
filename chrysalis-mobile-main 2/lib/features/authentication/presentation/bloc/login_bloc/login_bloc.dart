import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/di/service_locator.dart';
import 'package:chrysalis_mobile/core/local_storage/chat_file_storage.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/utils/device_utils.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/auth_error_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_request_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/login_usecase.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/register_key_usecase.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_event.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_state.dart';
import 'package:chrysalis_mobile/features/notifications/data/remote/notification_remote_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginIdChanged>(_onIdChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginErrorShown>(_onErrorShown);
    on<RegisterKeyEvent>(_onRegisterKey);
  }

  final CryptoService _cryptoService = CryptoService();
  String _id = '';
  String _password = '';

  void _onIdChanged(LoginIdChanged event, Emitter<LoginState> emit) {
    _id = event.id;
    final isValid = _id.isNotEmpty && _password.isNotEmpty;
    emit(LoginInitial(id: _id, password: _password, isValid: isValid));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    _password = event.password;
    final isValid = _id.isNotEmpty && _password.isNotEmpty;
    emit(LoginInitial(id: _id, password: _password, isValid: isValid));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final isValid = _id.isNotEmpty && _password.isNotEmpty;
    if (!isValid) return;
    emit(LoginLoading());
    final service = NotificationRemoteService();
    final token = await service.getToken();
    final deviceId = await DeviceUtils.getDeviceId();
    try {
      final response = await sl<LoginUseCase>()(
        LoginRequestEntity(
          login: _id,
          password: _password,
          fcmToken: token ?? '',
          deviceId: deviceId ?? '',
        ),
      );

      // Store tokens and login state
      final storage = sl<LocalStorage>();
      await storage.write(
        key: AppKeys.accessToken,
        value: response.tokens.accessToken,
      );
      await storage.write(
        key: AppKeys.refreshToken,
        value: response.tokens.refreshToken,
      );
      await storage.write(key: AppKeys.isLoggedIn, value: 'true');
      await storage.write(key: AppKeys.userID, value: response.user.id);

      // Clear file storage only on mobile platforms (not supported on web)
      if (!kIsWeb) {
        try {
          await ChatFileStorage().clearAll();
        } catch (e) {
          // Ignore file storage errors on unsupported platforms
        }
      }
      if (response.keys.hasKeys == true) {
        // Store keys securely
        await _cryptoService.saveKeysFromServer(
          publicKeyPem: response.keys.publicKey,
          privateKeyPem: response.keys.privateKey,
        );
      }
      emit(LoginSuccess(response));
    } catch (e) {
      String errorMessage;
      if (e is AuthErrorEntity) {
        errorMessage = e.message;
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'An unknown error occurred';
      }
      emit(LoginError(errorMessage));
    }
  }

  void _onErrorShown(LoginErrorShown event, Emitter<LoginState> emit) {
    emit(
      LoginInitial(
        id: _id,
        password: _password,
        isValid: _id.isNotEmpty && _password.isNotEmpty,
      ),
    );
  }

  Future<void> _onRegisterKey(
    RegisterKeyEvent event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(LoginLoading());
      await _cryptoService.generateKeyPairIfNeeded();
      final publicKeyPem = await _cryptoService.getPublicKeyPem() ?? '';
      final privateKeyEnc = await _cryptoService.getPrivateKeyPem() ?? '';
      final deviceId = await DeviceUtils.getDeviceId();

      await sl<RegisterKeyUsecase>()(
        publicKeyPem,
        privateKeyEnc,
        deviceId ?? 'unknown_device',
      );
      emit(RegisterKeySuccess());
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }
}
