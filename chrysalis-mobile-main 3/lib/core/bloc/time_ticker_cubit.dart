import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class TimeTickerCubit extends Cubit<DateTime> {
  TimeTickerCubit() : super(DateTime.now());
  Timer? _timer;

  void start({Duration interval = const Duration(minutes: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      emit(DateTime.now());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void tick() => emit(state);
}
