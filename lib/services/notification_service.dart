import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'notification_web_history_stub.dart'
    if (dart.library.js_interop) 'notification_web_history.dart';

enum NotificationDestination { home, journal, learn, progress }

enum NotificationPermission { notDetermined, granted, denied, unsupported }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.destination = NotificationDestination.home,
    this.isRead = false,
  });

  final String id;
  final String ownerUid;
  final String title;
  final String body;
  final DateTime receivedAt;
  final NotificationDestination destination;
  final bool isRead;

  static AppNotification? fromMessage(RemoteMessage message, String uid) {
    // A token can outlive an account. Never assign an unscoped message to the
    // account currently using this device.
    if (message.data['ownerUid'] != uid || uid.isEmpty) return null;
    final id = message.messageId;
    if (id == null || id.isEmpty) return null;
    return AppNotification(
      id: id,
      ownerUid: uid,
      title: _bounded(
        message.notification?.title ?? message.data['title'],
        160,
      ),
      body: _bounded(message.notification?.body ?? message.data['body'], 1000),
      receivedAt: message.sentTime ?? DateTime.now(),
      destination: parseDestination(message.data['destination']),
    );
  }

  static NotificationDestination parseDestination(Object? value) =>
      NotificationDestination.values.firstWhere(
        (destination) => destination.name == value,
        orElse: () => NotificationDestination.home,
      );

  AppNotification read() => AppNotification(
    id: id,
    ownerUid: ownerUid,
    title: title,
    body: body,
    receivedAt: receivedAt,
    destination: destination,
    isRead: true,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'ownerUid': ownerUid,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    'destination': destination.name,
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        ownerUid: json['ownerUid'] as String,
        title: _bounded(json['title'], 160),
        body: _bounded(json['body'], 1000),
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        destination: parseDestination(json['destination']),
        isRead: json['isRead'] == true,
      );

  static String _bounded(Object? value, int max) {
    final text = value is String ? value : '';
    return text.length > max ? text.substring(0, max) : text;
  }
}

/// One preference per message avoids overwriting the foreground inbox from a
/// background isolate. Async preferences bypass isolate-local caches.
class NotificationHistoryStore {
  NotificationHistoryStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const limit = 100;

  String _prefix(String uid) =>
      'vetalife.notifications.${base64Url.encode(utf8.encode(uid))}.';
  String _key(AppNotification item) =>
      '${_prefix(item.ownerUid)}${base64Url.encode(utf8.encode(item.id))}';

  Future<List<AppNotification>> load(String uid) async {
    final keys = await _preferences.getKeys();
    final items = <AppNotification>[];
    for (final key in keys.where((key) => key.startsWith(_prefix(uid)))) {
      try {
        final raw = await _preferences.getString(key);
        if (raw == null) continue;
        final item = AppNotification.fromJson(jsonDecode(raw));
        if (item.ownerUid == uid) items.add(item);
      } on FormatException {
        // One corrupt notification must not hide the rest of the inbox.
      } on TypeError {
        // Ignore invalid persisted payloads.
      }
    }
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items.take(limit).toList(growable: false);
  }

  Future<void> save(AppNotification item) async {
    final existing = await _preferences.getString(_key(item));
    if (existing != null && !item.isRead) {
      return; // Retain read state on replay.
    }
    await _preferences.setString(_key(item), jsonEncode(item.toJson()));
    final keys = await _preferences.getKeys();
    final all = <AppNotification>[];
    for (final key in keys.where(
      (key) => key.startsWith(_prefix(item.ownerUid)),
    )) {
      try {
        final raw = await _preferences.getString(key);
        if (raw != null) {
          all.add(AppNotification.fromJson(jsonDecode(raw)));
        }
      } on FormatException {
        await _preferences.remove(key);
      } on TypeError {
        await _preferences.remove(key);
      }
    }
    all.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    for (final expired in all.skip(limit)) {
      await _preferences.remove(_key(expired));
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseNotificationBackgroundHandler(
  RemoteMessage message,
) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final item = AppNotification.fromMessage(message, uid);
  if (item != null) await NotificationHistoryStore().save(item);
}

void registerNotificationBackgroundHandler() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseNotificationBackgroundHandler,
    );
  }
}

abstract interface class NotificationService {
  Stream<AppNotification> get messages;
  Stream<AppNotification> get opened;
  Future<NotificationPermission> initialize();
  Future<NotificationPermission> requestPermission();
  Future<List<AppNotification>> loadHistory();
  Future<void> markRead(AppNotification item);
  Future<void> disableForSignOut();
  Future<void> dispose();
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    required this.uid,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationHistoryStore? history,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _history = history ?? NotificationHistoryStore();

  final String uid;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationHistoryStore _history;
  final _messages = StreamController<AppNotification>.broadcast();
  final _opened = StreamController<AppNotification>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _disposed = false;
  bool _initialized = false;
  bool _launchInitialized = false;
  String? _webLaunchId;

  bool get _active => !_disposed && _auth.currentUser?.uid == uid;
  @override
  Stream<AppNotification> get messages => _messages.stream;
  @override
  Stream<AppNotification> get opened => _opened.stream;

  static NotificationPermission _permission(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => NotificationPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => NotificationPermission.denied,
        AuthorizationStatus.notDetermined =>
          NotificationPermission.notDetermined,
      };

  @override
  Future<NotificationPermission> initialize() async {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      return NotificationPermission.unsupported;
    }
    if (!await _messaging.isSupported()) {
      return NotificationPermission.unsupported;
    }
    if (!_active) return NotificationPermission.notDetermined;
    if (!_initialized) {
      _initialized = true;
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen(
          (message) => unawaited(_receive(message, tapped: false)),
        ),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(
          (message) => unawaited(_receive(message, tapped: true)),
        ),
      );
      _subscriptions.add(
        _messaging.onTokenRefresh.listen(
          (token) => unawaited(
            _registerToken(token).catchError((Object error, StackTrace stack) {
              if (_active) _messages.addError(error, stack);
            }),
          ),
        ),
      );
    }
    if (!_launchInitialized) {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) await _receive(initial, tapped: true);
      if (kIsWeb) {
        final id = _webLaunchId ??= takeWebNotificationLaunchId();
        if (id != null) {
          final history = await loadHistory();
          final matching = history.where(
            (item) => item.id == id && item.ownerUid == uid,
          );
          if (matching.isNotEmpty && _active) {
            final item = matching.first.read();
            await _history.save(item);
            if (_active) _opened.add(item);
          }
        }
      }
      _launchInitialized = true;
      _webLaunchId = null;
    }
    // Does not prompt on startup. Enabling is an explicit user action.
    final permission = _permission(await _messaging.getNotificationSettings());
    if (permission == NotificationPermission.granted) await _refreshToken();
    return permission;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!_active) throw StateError('Notification session ended');
    if (kIsWeb && const String.fromEnvironment('FCM_VAPID_KEY').isEmpty) {
      throw StateError('Web push is not configured');
    }
    final permission = _permission(await _messaging.requestPermission());
    if (permission == NotificationPermission.granted) await _refreshToken();
    return permission;
  }

  Future<void> _refreshToken() async {
    if (kIsWeb && const String.fromEnvironment('FCM_VAPID_KEY').isEmpty) return;
    if (!_active) return;
    await _messaging.setAutoInitEnabled(true);
    if (!_active) return;
    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? const String.fromEnvironment('FCM_VAPID_KEY') : null,
    );
    if (token != null) await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    if (!_active) return;
    if (utf8.encode(token).length > 1000) {
      throw StateError('Invalid messaging token length');
    }
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(base64Url.encode(utf8.encode(token)))
          .set({
            'token': token,
            'platform': kIsWeb ? 'web' : 'android',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // Exposed by explicit enable/retry, without leaking the token in logs.
      if (_active) rethrow;
    }
  }

  Future<void> _receive(RemoteMessage message, {required bool tapped}) async {
    if (!_active) return;
    final item = AppNotification.fromMessage(message, uid);
    if (item == null) return;
    try {
      await _history.save(tapped ? item.read() : item);
      if (!_active) return;
      (tapped ? _opened : _messages).add(item);
    } catch (error, stack) {
      if (_active) _messages.addError(error, stack);
    }
  }

  @override
  Future<List<AppNotification>> loadHistory() async {
    if (kIsWeb && _active) {
      final pending = await loadWebNotificationHistory(uid);
      for (final item in pending) {
        if (!_active) return [];
        await _history.save(item);
        // Delete only after local persistence succeeds so a transient failure
        // does not discard a notification captured by the background worker.
        await removeWebNotification(uid, item.id);
      }
    }
    return _history.load(uid);
  }

  @override
  Future<void> markRead(AppNotification item) async {
    if (!_active || item.ownerUid != uid) return;
    await _history.save(item.read());
  }

  @override
  Future<void> disableForSignOut() async {
    if (!_active) return;
    if (kIsWeb && const String.fromEnvironment('FCM_VAPID_KEY').isEmpty) return;
    if (!await _messaging.isSupported()) return;
    final permission = _permission(await _messaging.getNotificationSettings());
    if (permission != NotificationPermission.granted) return;
    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? const String.fromEnvironment('FCM_VAPID_KEY') : null,
    );
    if (!_active) return;
    // Revoke delivery before changing the authenticated account. Deleting only
    // the server record does not invalidate a token held by a sender.
    await _messaging.deleteToken();
    await _messaging.setAutoInitEnabled(false);
    if (token != null && _active) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(base64Url.encode(utf8.encode(token)))
          .delete();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _messages.close();
    await _opened.close();
  }
}
