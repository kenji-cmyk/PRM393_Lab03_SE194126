import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/services/lesson_progress_repository.dart';
import 'package:vetalife/viewmodels/learning_view_model.dart';

import 'lesson_test_fixtures.dart';

class _Repository implements LessonProgressRepository {
  List<LessonReadProgress> records = [];
  bool failLoad = false, failSave = false, failClear = false;
  int saves = 0;
  Completer<List<LessonReadProgress>>? pendingLoad;
  Completer<void>? pendingSave;
  @override
  Future<List<LessonReadProgress>> load() async {
    if (pendingLoad != null) return pendingLoad!.future;
    if (failLoad) throw StateError('private backend text');
    return List.of(records);
  }

  @override
  Future<void> save(LessonReadProgress progress) async {
    saves++;
    await pendingSave?.future;
    if (failSave) throw StateError('private backend text');
    records.removeWhere((item) => item.lessonId == progress.lessonId);
    records.add(progress);
  }

  @override
  Future<void> clearPreview() async {
    if (failClear) throw StateError('private backend text');
    records.clear();
  }
}

LearningViewModel _vm(_Repository repo) => LearningViewModel(
  repository: repo,
  loadCatalog: () async => lessonFixture(),
  now: () => DateTime.utc(2026, 11, 4, 12),
);
LessonReadProgress _progress(String id) =>
    LessonReadProgress(lessonId: id, readAt: DateTime.utc(2026, 11, 3));

void main() {
  test('opening never completes; explicit core and supplementary reads count separately', () async {
    final repo = _Repository();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.showProgress();
    vm.showCatalog();
    vm.selectPart('part-2');
    vm.openLesson('p2-introduction');
    expect(repo.saves, 0);
    expect(vm.completedCoreCount, 0);
    await vm.markSelectedRead();
    expect(vm.completedCoreCount, 0);
    expect(vm.lastReadLesson!.id, 'p2-introduction');
    vm.back();
    expect(vm.stage, LearningStage.catalog);
    expect(vm.selectedPartId, 'part-2');
    vm.openLesson('p2-dd01');
    await vm.markSelectedRead();
    await vm.markSelectedRead();
    expect(repo.saves, 2);
    expect(vm.completedCoreCount, 1);
    expect(vm.readProgress.length, 2);
    vm.back();
    vm.back();
    expect(vm.stage, LearningStage.progress);
  });
  test('pending save disables duplicate submission and navigation; success commits once', () async {
    final repo = _Repository()..pendingSave = Completer<void>();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.showCatalog();
    vm.openLesson('p1-ch01');
    final saving = vm.markSelectedRead();
    await vm.markSelectedRead();
    vm.back();
    vm.showHome();
    vm.openLesson('p1-ch02');
    expect(vm.isSaving, isTrue);
    expect(vm.selectedLesson!.id, 'p1-ch01');
    expect(vm.completedCoreCount, 0);
    expect(repo.saves, 1);
    repo.pendingSave!.complete();
    await saving;
    expect(vm.isSaving, isFalse);
    expect(vm.completedCoreCount, 1);
  });
  test('failed save preserves lesson and false completion, retry commits without exposing backend text', () async {
    final repo = _Repository()..failSave = true;
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.openLesson('p1-ch01');
    await vm.markSelectedRead();
    expect(vm.selectedLesson!.id, 'p1-ch01');
    expect(vm.isRead('p1-ch01'), isFalse);
    expect(vm.errorMessage, isNot(contains('private')));
    repo.failSave = false;
    await vm.retry();
    expect(vm.completedCoreCount, 1);
    expect(vm.errorMessage, isNull);
  });
  test('leaving a failed save clears its retry action instead of applying it to a different lesson', () async {
    final repo = _Repository()..failSave = true;
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.showProgress();
    vm.openLesson('p1-ch01');
    await vm.markSelectedRead();
    vm.back();
    vm.openLesson('p1-ch02');
    expect(vm.errorMessage, isNull);
    expect(vm.completedCoreCount, 0);
    expect(repo.saves, 1);
    vm.back();
    vm.back();
    expect(vm.stage, LearningStage.progress);
  });
  test('progress read failure permits loaded content but requires retry before writes', () async {
    final repo = _Repository()..failLoad = true;
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.catalog, isNotNull);
    expect(vm.errorMessage, isNotNull);
    vm.openLesson('p1-ch01');
    await vm.markSelectedRead();
    expect(repo.saves, 0);
    repo.failLoad = false;
    await vm.retry();
    expect(vm.selectedLesson!.id, 'p1-ch01');
    await vm.markSelectedRead();
    expect(vm.completedCoreCount, 1);
  });
  test(
    'unknown IDs cannot inflate progress and duplicate known IDs count once',
    () async {
      final repo = _Repository()
        ..records = [_progress('p1-ch01'), _progress('p1-ch01')];
      final vm = _vm(repo);
      addTearDown(vm.dispose);
      await vm.initialize();
      expect(vm.completedCoreCount, 1);
      repo.records = [_progress('invented')];
      await vm.initialize();
      expect(vm.errorMessage, isNotNull);
      expect(vm.completedCoreCount, 1); // last verified state retained
      vm.openLesson('invented');
      expect(vm.selectedLesson, isNull);
    },
  );
  test(
    'clear during pending initialization suppresses stale restored completion',
    () async {
      final repo = _Repository()
        ..pendingLoad = Completer<List<LessonReadProgress>>();
      final vm = _vm(repo);
      addTearDown(vm.dispose);
      final initializing = vm.initialize();
      await Future<void>.delayed(Duration.zero);
      await vm.clearPreviewSession();
      repo.pendingLoad!.complete([_progress('p1-ch01')]);
      await initializing;
      expect(vm.readProgress, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.stage, LearningStage.home);
    },
  );
  test('clear waits for pending persistence then removes it without resurrecting completion', () async {
    final repo = _Repository()..pendingSave = Completer<void>();
    final vm = _vm(repo);
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.openLesson('p1-ch01');
    final saving = vm.markSelectedRead();
    final clearing = vm.clearPreviewSession();
    repo.pendingSave!.complete();
    await Future.wait([saving, clearing]);
    expect(repo.records, isEmpty);
    expect(vm.readProgress, isEmpty);
    expect(vm.isSaving, isFalse);
  });
  test(
    'failed preview clear retains progress and can be retried safely',
    () async {
      final repo = _Repository()..records = [_progress('p1-ch01')];
      final vm = _vm(repo);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.failClear = true;
      await expectLater(vm.clearPreviewSession(), throwsStateError);
      expect(vm.completedCoreCount, 1);
      repo.failClear = false;
      await vm.clearPreviewSession();
      expect(vm.completedCoreCount, 0);
    },
  );
  test('dispose during read or write discards completion and does not notify again', () async {
    final repo = _Repository()..pendingSave = Completer<void>();
    final vm = _vm(repo);
    await vm.initialize();
    vm.openLesson('p1-ch01');
    final saving = vm.markSelectedRead();
    vm.dispose();
    repo.pendingSave!.complete();
    await saving;
    expect(vm.completedCoreCount, 0);
    final loadRepo = _Repository()
      ..pendingLoad = Completer<List<LessonReadProgress>>();
    final loading = _vm(loadRepo);
    final pending = loading.initialize();
    loading.dispose();
    loadRepo.pendingLoad!.complete([_progress('p1-ch01')]);
    await pending;
    expect(loading.completedCoreCount, 0);
  });
}
