import 'dart:async';

class AuthExpirationBus {
  AuthExpirationBus._();
  static final _controller = StreamController<void>.broadcast();
  static Stream<void> get events => _controller.stream;
  static void notify() => _controller.add(null);
}
