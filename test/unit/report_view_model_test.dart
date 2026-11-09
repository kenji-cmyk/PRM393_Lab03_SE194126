import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/services/report_service.dart';
import 'package:vetalife/viewmodels/report_view_model.dart';

ReportData _data() => ReportData(
  profile: UserProfile(
    displayName: 'Nguyễn Ánh',
    birthDate: DateTime(2000, 2, 29),
    weightKg: 60,
    heightCm: 170,
    goal: HabitGoal.readDaily,
  ),
  meals: const [],
  progress: const [],
);

class _Reports implements ReportService {
  int uploads = 0;
  int downloads = 0;
  int opened = 0;
  int cancellations = 0;
  bool fail = false;
  Completer<UploadedReport>? pending;
  final bytes = Uint8List.fromList([37, 80, 68, 70]);
  @override
  Future<Uint8List> generate(ReportData data) async => bytes;
  @override
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    uploads++;
    progress(.5);
    if (fail) throw StateError('offline');
    if (pending != null) return pending!.future;
    return const UploadedReport(
      path: 'reports/owner/1.pdf',
      storageUri: 'gs://bucket/reports/owner/1.pdf',
    );
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }

  @override
  Future<Uint8List> download(UploadedReport report) async {
    downloads++;
    return bytes;
  }

  @override
  Future<void> open(Uint8List bytes) async {
    opened++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('preview generates and opens locally without cloud upload', () async {
    final service = _Reports();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: true,
    );
    await vm.generate();
    expect(vm.canOpen, isTrue);
    expect(vm.uploaded, isNull);
    expect(service.uploads, 0);
    await vm.open();
    expect(service.downloads, 0);
    expect(service.opened, 1);
    vm.dispose();
  });
  test(
    'cloud open downloads with authentication and emits successful events',
    () async {
      final service = _Reports();
      final events = <String>[];
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
        onEvent: events.add,
      );
      await vm.generate();
      expect(vm.uploaded?.storageUri, startsWith('gs://'));
      expect(vm.progress, .5);
      await vm.open();
      expect(service.downloads, 1);
      expect(events, ['report_generated', 'report_uploaded', 'report_opened']);
      vm.dispose();
    },
  );
  test(
    'failed upload shows error and permits retry without stale success',
    () async {
      final service = _Reports()..fail = true;
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
      );
      await vm.generate();
      expect(vm.errorMessage, isNotNull);
      expect(vm.canOpen, isFalse);
      expect(vm.uploaded, isNull);
      service.fail = false;
      await vm.generate();
      expect(vm.errorMessage, isNull);
      expect(vm.canOpen, isTrue);
      vm.dispose();
    },
  );
  test('cancel while snapshot loads prevents generation and upload', () async {
    final service = _Reports();
    final snapshot = Completer<ReportData>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () => snapshot.future,
      isPreview: false,
    );
    final operation = vm.generate();
    await vm.cancel();
    snapshot.complete(_data());
    await operation;
    expect(service.uploads, 0);
    expect(vm.canOpen, isFalse);
    expect(vm.isBusy, isFalse);
    vm.dispose();
  });
  test('dispose and cancellation ignore late upload responses', () async {
    final service = _Reports()..pending = Completer<UploadedReport>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: false,
    );
    final operation = vm.generate();
    await Future<void>.delayed(Duration.zero);
    expect(service.uploads, 1);
    vm.dispose();
    service.pending!.complete(
      const UploadedReport(path: 'old-owner', storageUri: 'gs://old-owner'),
    );
    await operation;
    expect(vm.uploaded, isNull);
    expect(vm.canOpen, isFalse);
    expect(service.cancellations, 1);
  });
  test('duplicate requests do not upload twice', () async {
    final service = _Reports()..pending = Completer<UploadedReport>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: false,
    );
    final operation = vm.generate();
    await Future<void>.delayed(Duration.zero);
    await vm.generate();
    expect(service.uploads, 1);
    service.pending!.complete(
      const UploadedReport(path: 'owner', storageUri: 'gs://owner'),
    );
    await operation;
    vm.dispose();
  });
  test(
    'PDF generation loads bundled Vietnamese fonts and real empty state',
    () async {
      // Flutter test replaces font assets with empty buffers by default.
      // Exercise the actual repository font bytes used by the PDF renderer.
      final service = PdfReportService(
        now: () => DateTime(2026, 11, 9),
        loadFont: (path) => SynchronousFuture(
          ByteData.sublistView(File(path).readAsBytesSync()),
        ),
      );
      final bytes = await service.generate(_data());
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
      expect(bytes.length, lessThan(maxReportBytes));
      if (const bool.fromEnvironment('REPORT_PDF_QA')) {
        final example = ReportData(
          profile: _data().profile,
          meals: List.generate(
            35,
            (i) => MealRecord(
              id: 'qa_$i',
              draft: MealDraft(
                id: 'qa_$i',
                name: 'Đậu hũ, rau xanh và gạo lứt — bữa ăn mẫu ${i + 1}',
                mealType: MealType.lunch,
                eatenAt: DateTime(2026, 11, 9).subtract(Duration(days: i)),
                ingredients: List.generate(
                  6,
                  (n) => MealIngredient(
                    name: 'Rau xanh và đậu hũ loại ${n + 1}',
                    amount: 'Một phần vừa',
                    preparation: 'Hấp, luộc, thêm ít gia vị sau khi nấu',
                  ),
                ),
              ),
              analysis: MealAnalysis(
                title: 'Mẫu kiểm tra bố cục',
                summary: '',
                highlights: const [],
                improvements: const [],
                profileNote: '',
                limitations: const [],
                references: const [],
                healthConnections: const [],
                mode: 'localBook',
              ),
              savedAt: DateTime(2026, 11, 9),
            ),
          ),
          progress: [
            LessonReadProgress(
              lessonId: 'p1-ch01',
              readAt: DateTime.utc(2026, 11, 9),
            ),
          ],
        );
        final output = File('tmp/pdfs/report-preview.pdf');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(await service.generate(example));
      }
    },
  );
  test(
    'unauthenticated and switched accounts cannot upload or download',
    () async {
      var current = 'owner';
      final service = PdfReportService(
        uid: 'owner',
        currentUserId: () => current,
      );
      current = 'other';
      await expectLater(service.upload(Uint8List(1), (_) {}), throwsStateError);
      await expectLater(
        service.download(
          const UploadedReport(
            path: 'reports/owner/1.pdf',
            storageUri: 'gs://bucket/path',
          ),
        ),
        throwsStateError,
      );
    },
  );
}
