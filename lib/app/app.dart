import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/app_providers.dart';
import '../core/notifications/notification_service.dart';
import '../core/network/auth_expiration_bus.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SafeRideApp extends ConsumerStatefulWidget {
  const SafeRideApp({super.key});
  @override
  ConsumerState<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends ConsumerState<SafeRideApp> {
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<void>? _expirationSubscription;
  @override
  void initState() {
    super.initState();
    _tokenSubscription = NotificationService.instance.tokenRefresh.listen(
      _registerToken,
    );
    _expirationSubscription = AuthExpirationBus.events.listen(
      (_) => ref.read(sessionProvider.notifier).expire(),
    );
  }

  Future<void> _registerToken(String token) async {
    if (ref.read(sessionProvider).status != SessionStatus.authenticated) return;
    try {
      await ref.read(appRepositoryProvider).registerDeviceToken(token);
    } catch (_) {
      /* Retried on the next refresh or sign-in. */
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _expirationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (previous, next) async {
      if (next.status != SessionStatus.authenticated) return;
      final token = await NotificationService.instance.requestToken();
      if (token != null) await _registerToken(token);
    });
    return MaterialApp.router(
      title: 'SafeRide-LK',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
