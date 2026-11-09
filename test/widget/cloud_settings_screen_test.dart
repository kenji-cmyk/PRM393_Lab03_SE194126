import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/screens/cloud_settings_screen.dart';
import 'package:vetalife/services/app_settings.dart';

class _Source implements AppSettingsSource {
  bool fail = true;
  @override
  Future<Map<String, bool>> fetch() async {
    if (fail) throw StateError('private data');
    return {'learning_enabled': false, 'report_export_enabled': false};
  }
}

void main() {
  testWidgets(
    'narrow settings exposes retry and refreshed feature states without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = _Source();
      final settings = AppSettings(source: source);
      addTearDown(settings.dispose);
      await settings.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: CloudSettingsScreen(settings: settings, isPreview: false),
          ),
        ),
      );
      expect(find.textContaining('Chưa tải được cấu hình'), findsOneWidget);
      expect(find.text('Tạo crash kiểm thử'), findsNothing);
      source.fail = false;
      await tester.tap(find.text('Tải lại cấu hình'));
      await tester.pumpAndSettle();
      expect(find.text('Tạm đóng'), findsNWidgets(2));
      expect(find.textContaining('Chưa tải được cấu hình'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
