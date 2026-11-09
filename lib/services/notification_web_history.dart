import 'dart:convert';
import 'dart:js_interop';

import 'notification_service.dart';

@JS('vetalifeNotificationHistoryLoad')
external JSPromise<JSArray<JSString>> _load(JSString uid);

@JS('vetalifeNotificationHistoryRemove')
external JSPromise<JSAny?> _remove(JSString uid, JSString id);

@JS('vetalifeNotificationTakeLaunchId')
external JSString? _takeLaunchId();

String? takeWebNotificationLaunchId() => _takeLaunchId()?.toDart;

Future<List<AppNotification>> loadWebNotificationHistory(String uid) async {
  final raw = await _load(uid.toJS).toDart;
  final result = <AppNotification>[];
  for (final json in raw.toDart) {
    try {
      final item = AppNotification.fromJson(jsonDecode(json.toDart));
      if (item.ownerUid == uid) result.add(item);
    } on FormatException {
      // Ignore invalid persisted messages.
    } on TypeError {
      // Ignore invalid persisted messages.
    }
  }
  return result;
}

Future<void> removeWebNotification(String uid, String id) async {
  await _remove(uid.toJS, id.toJS).toDart;
}
