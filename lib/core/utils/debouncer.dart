import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  Future<void> runAsync(VoidCallback action) async {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  Future<void> disposeAsync() async {
    _timer?.cancel();
    _timer = null;
  }
}