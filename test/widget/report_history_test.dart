import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/screens/report_screen.dart';
import 'package:vetalife/services/report_service.dart';
import 'package:vetalife/theme/app_theme.dart';
import 'package:vetalife/viewmodels/report_view_model.dart';

final _saved = SavedReport(
  report: const UploadedReport(
    path: 'users/owner/reports/private-one',
    storageUri: 'firestore://users/owner/reports/private-one',
  ),
  createdAt: DateTime(2026, 11, 12, 8, 30),
  sizeBytes: 4096,
);

class _Archive implements ReportService, ReportArchive {
  int lists = 0;
  int downloads = 0;
  int opened = 0;
  bool fail = false;
  List<SavedReport> reports = [_saved];
  Completer<List<SavedReport>>? pending;

  @override
  Future<List<SavedReport>> listRecent() async {
    lists++;
    if (fail) throw StateError('offline');
    return pending == null ? reports : pending!.future;
  }

  @override
  Future<Uint8List> generate(ReportData data) async =>
      Uint8List.fromList([37, 80, 68, 70]);
  @override
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  ) async => _saved.report;
  @override
  Future<Uint8List> download(UploadedReport report) async {
    downloads++;
    return Uint8List.fromList([37, 80, 68, 70]);
  }

  @override
  Future<void> open(Uint8List bytes) async {
    opened++;
  }

  @override
  Future<void> cancel() async {}
}

ReportViewModel _model(_Archive archive, {bool preview = false}) =>
    ReportViewModel(
      service: archive,
      snapshot: () async => ReportData(
        profile: UserProfile(
          displayName: 'Test',
          birthDate: DateTime(2000, 1, 1),
          weightKg: 60,
          heightCm: 170,
          goal: HabitGoal.readDaily,
        ),
        meals: const [],
        progress: const [],
      ),
      isPreview: preview,
    );

Widget _app(ReportViewModel model, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: ReportScreen(viewModel: model),
  ),
);

void main() {
  testWidgets(
    'loads saved reports on entry and opens private PDF without showing storage path',
    (tester) async {
      final archive = _Archive();
      final model = _model(archive);
      addTearDown(model.dispose);
      await tester.pumpWidget(_app(model));
      await tester.pumpAndSettle();
      expect(archive.lists, 1);
      await tester.scrollUntilVisible(find.text('Mở báo cáo đã lưu'), 200);
      expect(find.textContaining('12/11/2026'), findsOneWidget);
      expect(find.textContaining('4.0 KiB'), findsOneWidget);
      expect(find.textContaining('firestore://'), findsNothing);
      await tester.tap(find.text('Mở báo cáo đã lưu'));
      await tester.pumpAndSettle();
      expect(archive.downloads, 1);
      expect(archive.opened, 1);
    },
  );

  testWidgets('history failure offers retry and empty archive is explicit', (
    tester,
  ) async {
    final archive = _Archive()..fail = true;
    final model = _model(archive);
    addTearDown(model.dispose);
    await tester.pumpWidget(_app(model));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Thử tải lại báo cáo'), 200);
    expect(find.textContaining('Chưa tải được báo cáo'), findsOneWidget);
    archive
      ..fail = false
      ..reports = [];
    await tester.tap(find.text('Thử tải lại báo cáo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có báo cáo đã lưu'), findsOneWidget);
    expect(archive.lists, 2);
  });

  testWidgets('saved report layout supports narrow width with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final archive = _Archive();
    final model = _model(archive);
    addTearDown(model.dispose);
    await tester.pumpWidget(_app(model, textScale: 2));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(find.text('Mở báo cáo đã lưu').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Mở báo cáo đã lưu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(archive.opened, 1);
  });

  testWidgets('preview does not load or show the cloud archive', (
    tester,
  ) async {
    final archive = _Archive();
    final model = _model(archive, preview: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(_app(model));
    await tester.pumpAndSettle();
    expect(archive.lists, 0);
    expect(find.text('Báo cáo đã lưu'), findsNothing);
  });
}
