import 'package:chrysalis_mobile/core/local_storage/chat_file_storage.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/logout_usecase.dart';
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
    emit(LogoutInProgress());
    try {
      // final accessToken = await LocalStorage().read(key: 'accessToken');
      // final refreshToken = await LocalStorage().read(key: 'refreshToken');
      // if (accessToken == null || refreshToken == null) {
      //   await _clearLocalStorage();
      //   emit(LogoutSuccess());
      //   return;
      // }
      // final request = LogoutRequestModel(refreshToken: refreshToken);
      // await logoutUseCase(request, accessToken);
      // await _clearLocalStorage();
      await _clearLocalStorage();
      emit(LogoutSuccess());
    } catch (e) {
      await _clearLocalStorage();
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
