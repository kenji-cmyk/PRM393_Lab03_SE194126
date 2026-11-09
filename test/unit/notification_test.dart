import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetalife/services/notification_service.dart';
import 'package:vetalife/viewmodels/notification_view_model.dart';

class _Preferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async =>
      values.keys.toSet();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppNotification _item(String id, {String uid = 'alice', int minute = 0}) =>
    AppNotification(
      id: id,
      ownerUid: uid,
      title: 'VetaLife',
      body: 'Đọc bài học',
      receivedAt: DateTime.utc(2026, 11, 9, 0, minute),
      destination: NotificationDestination.learn,
    );

class _Service implements NotificationService {
  final incoming = StreamController<AppNotification>.broadcast();
  final taps = StreamController<AppNotification>.broadcast();
  List<AppNotification> history = [];
  int permissionRequests = 0;
  NotificationPermission permission = NotificationPermission.notDetermined;
  Completer<List<AppNotification>>? delayedLoad;
  @override
  Stream<AppNotification> get messages => incoming.stream;
  @override
  Stream<AppNotification> get opened => taps.stream;
  @override
  Future<NotificationPermission> initialize() async => permission;
  @override
  Future<NotificationPermission> requestPermission() async {
    permissionRequests++;
    return NotificationPermission.denied;
  }

  @override
  Future<List<AppNotification>> loadHistory() =>
      delayedLoad?.future ?? Future.value(history);
  @override
  Future<void> markRead(AppNotification item) async => history = [item.read()];
  @override
  Future<void> disableForSignOut() async {}
  @override
  Future<void> dispose() async {
    await incoming.close();
    await taps.close();
  }
}

class _User implements User {
  @override
  String get uid => 'alice';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  @override
  User get currentUser => _User();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Firestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NotificationSettings implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus =>
      AuthorizationStatus.notDetermined;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingStream<T> extends Stream<T> {
  _CountingStream(this.source);
  final Stream<T> source;
  int subscriptions = 0;
  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    subscriptions++;
    return source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _Messaging implements FirebaseMessaging {
  final tokens = StreamController<String>.broadcast();
  late final tokenStream = _CountingStream(tokens.stream);
  int initialRequests = 0;
  @override
  Stream<String> get onTokenRefresh => tokenStream;
  @override
  Future<bool> isSupported() async => true;
  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      _NotificationSettings();
  @override
  Future<RemoteMessage?> getInitialMessage() async {
    initialRequests++;
    if (initialRequests == 1) {
      throw StateError('Transient launch transport error');
    }
    return const RemoteMessage(
      messageId: 'launch-message',
      data: {
        'ownerUid': 'alice',
        'destination': 'journal',
        'title': 'VetaLife',
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('retry after initial-message failure recovers one persisted tap without duplicate subscriptions', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final messaging = _Messaging();
    addTearDown(messaging.tokens.close);
    final service = FirebaseNotificationService(
      uid: 'alice',
      messaging: messaging,
      auth: _Auth(),
      firestore: _Firestore(),
      history: NotificationHistoryStore(preferences: _Preferences()),
    );
    addTearDown(service.dispose);
    final opened = <AppNotification>[];
    final subscription = service.opened.listen(opened.add);
    addTearDown(subscription.cancel);
    await expectLater(service.initialize(), throwsStateError);
    expect(opened, isEmpty);
    expect(messaging.tokenStream.subscriptions, 1);

    expect(await service.initialize(), NotificationPermission.notDetermined);
    expect(messaging.initialRequests, 2);
    expect(opened.single.id, 'launch-message');
    expect(opened.single.destination, NotificationDestination.journal);
    final history = await service.loadHistory();
    expect(history.single.id, 'launch-message');
    expect(history.single.isRead, isTrue);

    await service.initialize();
    expect(messaging.initialRequests, 2);
    expect(opened, hasLength(1));
    expect(messaging.tokenStream.subscriptions, 1);
    expect(await service.loadHistory(), hasLength(1));
  });

  test('message ownership is required and destinations are allowlisted', () {
    expect(
      AppNotification.fromMessage(const RemoteMessage(messageId: '1'), 'alice'),
      isNull,
    );
    expect(
      AppNotification.fromMessage(
        const RemoteMessage(messageId: '1', data: {'ownerUid': 'bob'}),
        'alice',
      ),
      isNull,
    );
    final item = AppNotification.fromMessage(
      const RemoteMessage(
        messageId: '1',
        data: {'ownerUid': 'alice', 'destination': 'https://evil.test'},
      ),
      'alice',
    );
    expect(item!.destination, NotificationDestination.home);
  });

  test('history survives a new store without leaking another account or read state', () async {
    final preferences = _Preferences();
    final store = NotificationHistoryStore(preferences: preferences);
    final item = _item('1');
    await store.save(item);
    await store.save(_item('1', uid: 'bob'));
    await store.save(item.read());
    await store.save(item); // Duplicate foreground/background delivery.
    final reloaded = NotificationHistoryStore(preferences: preferences);
    expect((await reloaded.load('alice')).single.isRead, isTrue);
    expect((await reloaded.load('bob')).single.ownerUid, 'bob');
    expect(await reloaded.load('carol'), isEmpty);
  });

  test(
    'history is bounded, newest first, and ignores corrupt entries',
    () async {
      final preferences = _Preferences();
      final store = NotificationHistoryStore(preferences: preferences);
      for (var i = 0; i < 105; i++) {
        await store.save(_item('$i', minute: i));
      }
      final items = await store.load('alice');
      expect(items, hasLength(NotificationHistoryStore.limit));
      expect(preferences.values, hasLength(NotificationHistoryStore.limit));
      expect(items.first.id, '104');
      expect(items.last.id, '5');
      preferences.values[preferences.values.keys.first] = '{invalid';
      expect(await store.load('alice'), hasLength(99));
    },
  );

  test('permission is requested explicitly, denial remains visible', () async {
    final service = _Service();
    final vm = NotificationViewModel(service);
    await vm.initialize();
    expect(service.permissionRequests, 0);
    await vm.enable();
    expect(service.permissionRequests, 1);
    expect(vm.permission, NotificationPermission.denied);
    vm.dispose();
  });

  test(
    'opening marks read and consumes only an allowlisted destination',
    () async {
      final service = _Service();
      final vm = NotificationViewModel(service);
      await vm.initialize();
      await vm.open(_item('1'));
      expect(vm.items.single.isRead, isTrue);
      expect(vm.takeDestination(), NotificationDestination.learn);
      expect(vm.takeDestination(), isNull);
      vm.dispose();
    },
  );

  test('disposed account cannot publish a delayed history load', () async {
    final service = _Service();
    final vm = NotificationViewModel(service);
    await vm.initialize();
    service.delayedLoad = Completer<List<AppNotification>>();
    final refresh = vm.refresh();
    vm.dispose();
    service.delayedLoad!.complete([_item('1')]);
    await refresh;
    expect(vm.items, isEmpty);
  });
}
