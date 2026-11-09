import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/services/app_settings.dart';

class _Source implements AppSettingsSource {
  Map<String, bool> values = {};
  bool fail = false;
  Completer<Map<String, bool>>? gate;
  int calls = 0;
  @override
  Future<Map<String, bool>> fetch() async {
    calls++;
    if (gate != null) return gate!.future;
    if (fail) throw StateError('private payload');
    return values;
  }
}

void main() {
  test('preview has defaults and never requires Firebase', () async {
    final settings = AppSettings();
    addTearDown(settings.dispose);
    await settings.initialize();
    expect(settings.learningEnabled, isTrue);
    expect(settings.reportExportEnabled, isTrue);
    expect(settings.isCloud, isFalse);
  });
  test('fetch changes both visible gates; failure keeps previous values and retry recovers', () async {
    final source = _Source()
      ..values = {'learning_enabled': false, 'report_export_enabled': false};
    final settings = AppSettings(source: source);
    addTearDown(settings.dispose);
    await settings.initialize();
    expect(settings.learningEnabled, isFalse);
    expect(settings.reportExportEnabled, isFalse);
    source.fail = true;
    await settings.refresh();
    expect(settings.learningEnabled, isFalse);
    expect(settings.errorMessage, isNot(contains('private payload')));
    source.fail = false;
    source.values = {'learning_enabled': true};
    await settings.refresh();
    expect(settings.learningEnabled, isTrue);
    expect(settings.reportExportEnabled, isFalse);
    expect(settings.errorMessage, isNull);
  });
  test(
    'pending fetch locks duplicates and disposal ignores delayed response',
    () async {
      final source = _Source()..gate = Completer<Map<String, bool>>();
      final settings = AppSettings(source: source);
      final pending = settings.refresh();
      await settings.refresh();
      expect(source.calls, 1);
      settings.dispose();
      source.gate!.complete({'learning_enabled': false});
      await pending;
      expect(settings.learningEnabled, isTrue);
    },
  );
}
