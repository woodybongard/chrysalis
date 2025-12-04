import 'package:chrysalis_mobile/features/notifications/presentation/bloc/notification_event.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/bloc/notification_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationInitial()) {
    on<NotificationReceived>((event, emit) {
      emit(NotificationReceivedState(event.message));
    });
    on<NotificationClear>((event, emit) {
      emit(NotificationInitial());
    });
  }
}
