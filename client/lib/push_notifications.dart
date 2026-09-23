import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Public marketplace updates; this topic must never carry private account data.
class PushNotifications with WidgetsBindingObserver {
  PushNotifications._();
  static final instance = PushNotifications._();
  static const _channel = MethodChannel(
    'com.torikdammam.marketplace/notifications',
  );
  static const _topic = 'marketplace_new_posts';
  bool _ready = false;
  bool _syncing = false;

  Future<void> initialize() async {
    if (_ready || kIsWeb || defaultTargetPlatform != TargetPlatform.android)
      return;
    try {
      await Firebase.initializeApp();
      await _channel.invokeMethod<void>('initialize');
      _ready = true;
      WidgetsBinding.instance.addObserver(this);
      FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForeground(message));
      });
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) {
          unawaited(_syncSubscription());
        },
        onError: (Object _) {
          debugPrint('Push token refresh failed; retrying on next resume.');
        },
      );
      await FirebaseMessaging.instance.requestPermission();
      await _syncSubscription();
    } catch (_) {
      debugPrint(
        'Android push initialization failed. Check Firebase configuration.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_syncSubscription());
  }

  Future<void> _syncSubscription() async {
    if (!_ready || _syncing) return;
    _syncing = true;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await FirebaseMessaging.instance.subscribeToTopic(_topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_topic);
      }
    } catch (_) {
      debugPrint('Push subscription unavailable; retrying on next resume.');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _channel.invokeMethod<void>('show', {
        'id': message.data['postId'] ?? message.messageId ?? 'new-post',
        'title': notification.title ?? 'New post on Torik Dammam',
        'body': notification.body ?? '',
      });
    } catch (_) {
      debugPrint('Foreground notification could not be displayed.');
    }
  }
}
