import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';
import '../utils/calendar_date.dart';
import '../viewmodels/learning_view_model.dart';
import '../viewmodels/meal_view_model.dart';
import '../widgets/app_components.dart';
import '../widgets/meal_navigation.dart';

/// Figma flow 3: real weekly records, book catalogue and a source-mapped reader.
/// The session owner supplies repositories; widgets never call Firebase.
class LearningFlowScreen extends StatelessWidget {
  const LearningFlowScreen({
    super.key,
    required this.onHome,
    required this.onJournal,
    this.now,
  });

  final VoidCallback onHome;
  final VoidCallback onJournal;
  final DateTime Function()? now;

  void _back(LearningViewModel vm) {
    if (vm.isSaving) return;
    vm.back();
    if (vm.stage == LearningStage.home) onHome();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearningViewModel>();
    final meals = context.watch<MealViewModel?>();
    final busy = vm.isSaving || (meals?.isSaving ?? false);
    final detail = vm.stage == LearningStage.detail;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _back(vm);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: detail,
          child: _LearningPage(
            key: ValueKey((vm.stage, vm.selectedLesson?.id)),
            scrollKey: PageStorageKey(
              'learning-${vm.stage.name}-${vm.selectedPartId}-${vm.selectedLesson?.id ?? ''}',
            ),
            child: vm.isLoading && vm.catalog == null
                ? const AppLoadingState(message: 'Đang tải bài học…')
                : vm.catalog == null
                ? _LearningFailure(
                    message: vm.errorMessage ?? 'Chưa tải được mục lục sách.',
                    onRetry: vm.retry,
                    onBack: () => _back(vm),
                  )
                : switch (vm.stage) {
                    LearningStage.detail => _LessonReader(
                      onBack: () => _back(vm),
                    ),
                    LearningStage.catalog => _LessonCatalogue(
                      onBack: () => _back(vm),
                    ),
                    LearningStage.home ||
                    LearningStage.progress => _WeeklyProgress(
                      now: (now ?? DateTime.now)(),
                      onJournal: onJournal,
                    ),
                  },
          ),
        ),
        bottomNavigationBar: detail
            ? null
            : AbsorbPointer(
                absorbing: busy,
                child: MealNavigation(
                  selectedIndex: vm.stage == LearningStage.catalog ? 3 : 2,
                  onSelected: (index) {
                    if (busy) return;
                    switch (index) {
                      case 0:
                        onHome();
                      case 1:
                        onJournal();
                      case 2:
                        vm.showProgress();
                      case 3:
                        vm.showCatalog();
                    }
                  },
                ),
              ),
      ),
    );
  }
}

class _LearningPage extends StatelessWidget {
  const _LearningPage({
    super.key,
    required this.child,
    required this.scrollKey,
  });
  final Widget child;
  final PageStorageKey<String> scrollKey;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTokens.contentMaxWidth),
      child: SingleChildScrollView(
        key: scrollKey,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageInset,
          AppTokens.space4,
          AppTokens.pageInset,
          AppTokens.space24,
        ),
        child: child,
      ),
    ),
  );
}

class _LearningFailure extends StatelessWidget {
  const _LearningFailure({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTopBar(title: 'Bài học nhỏ', onBack: onBack),
      const SizedBox(height: AppTokens.space24),
      Text(
        'Chưa thể tải bài học',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppTokens.space12),
      AppInlineError(message: message),
      const SizedBox(height: AppTokens.space24),
      AppButton(label: 'Thử lại', onPressed: onRetry),
    ],
  );
}

class _ProgressError extends StatelessWidget {
  const _ProgressError();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearningViewModel>();
    if (vm.errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInlineError(message: vm.errorMessage!),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: vm.isSaving || vm.isLoading ? null : vm.retry,
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.now, required this.onJournal});
  final DateTime now;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearningViewModel>();
    final meals = context.watch<MealViewModel?>();
    final theme = Theme.of(context);
    final week = LearningWeekSummary.fromRecords(meals?.records ?? [], now);
    final journalFailed = meals?.journalError != null;
    final journalLoading = meals?.isLoadingJournal ?? false;
    final lastRead = vm.lastReadLesson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppTopBar(title: 'Tiến trình tuần'),
        const SizedBox(height: AppTokens.space24),
        Semantics(
          label:
              'Tuần này, từ ${formatCalendarDate(week.start, iso: false)} '
              'đến ${formatCalendarDate(week.end, iso: false)}',
          excludeSemantics: true,
          child: Text('Tuần này', style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: AppTokens.space12),
        if (journalLoading)
          const AppLoadingState(message: 'Đang tải nhật ký…')
        else if (journalFailed) ...[
          AppInlineError(message: meals!.journalError!),
          TextButton(
            onPressed: onJournal,
            child: const Text('Mở nhật ký để thử lại'),
          ),
        ] else ...[
          AppCard(
            key: const ValueKey('learning-week-count'),
            title: 'Ngày ghi bữa ăn',
            body: '${week.recordedDays} trong 7 ngày',
            selected: true,
          ),
          const SizedBox(height: AppTokens.space16),
          Text(
            'Số bữa ăn đã lưu mỗi ngày',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space8),
          _WeekChart(week: week),
          const SizedBox(height: AppTokens.space8),
          Text(
            week.textAlternative,
            key: const ValueKey('learning-chart-alternative'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          AppCard(
            title: week.recordedDays == 0
                ? 'Bắt đầu từ một bữa ăn'
                : 'Điểm sáng',
            body: week.recordedDays == 0
                ? 'Tuần này chưa có bữa ăn được lưu. Ghi lại bữa gần nhất khi bạn sẵn sàng.'
                : 'Bạn đã ghi nhận bữa ăn trong ${week.recordedDays} ngày tuần này.',
          ),
        ],
        const SizedBox(height: AppTokens.space8),
        TextButton(
          key: const ValueKey('learning-open-catalogue'),
          onPressed: vm.isSaving ? null : vm.showCatalog,
          child: const Text('Khám phá mục lục sách  →'),
        ),
        const SizedBox(height: AppTokens.space8),
        const _ProgressError(),
        if (vm.progressReady)
          Text(
            'Đã đọc ${vm.completedCoreCount}/${vm.catalog!.coreCount} bài chính',
            key: const ValueKey('learning-read-count'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        const SizedBox(height: AppTokens.space8),
        Text(
          !vm.progressReady
              ? 'Tiến độ đã đọc chưa sẵn sàng.'
              : lastRead == null
              ? 'Chưa đánh dấu bài học.'
              : 'Đọc gần nhất: ${lastRead.displayTitle}',
          key: const ValueKey('learning-last-read'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (lastRead != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: vm.isSaving ? null : () => vm.openLesson(lastRead.id),
              child: const Text('Đọc lại bài này'),
            ),
          ),
      ],
    );
  }
}

/// A local Monday–Sunday summary, shared by bars, counts and text alternatives.
class LearningWeekSummary {
  LearningWeekSummary._({required this.start, required List<int> counts})
    : counts = List.unmodifiable(counts);

  factory LearningWeekSummary.fromRecords(
    List<MealRecord> records,
    DateTime now,
  ) {
    final today = calendarDate(now.toLocal());
    final start = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final counts = List.filled(7, 0);
    final seenIds = <String>{};
    for (final record in records) {
      if (!seenIds.add(record.id)) continue;
      final day = calendarDate(record.draft.eatenAt.toLocal());
      final index = DateTime.utc(
        day.year,
        day.month,
        day.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
      if (index >= 0 && index < 7 && !day.isAfter(today)) counts[index]++;
    }
    return LearningWeekSummary._(start: start, counts: counts);
  }

  static const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final DateTime start;
  final List<int> counts;
  DateTime get end => DateTime(start.year, start.month, start.day + 6);
  int get recordedDays => counts.where((count) => count > 0).length;
  int get maxCount =>
      counts.fold(1, (largest, count) => count > largest ? count : largest);
  String get textAlternative => List.generate(
    7,
    (index) => '${dayLabels[index]}: ${counts[index]} bữa',
  ).join(' · ');
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week});
  final LearningWeekSummary week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTokens.border)),
          ),
          child: SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: Semantics(
                      label:
                          '${LearningWeekSummary.dayLabels[index]}: ${week.counts[index]} bữa ăn đã lưu',
                      child: Tooltip(
                        message: '${week.counts[index]} bữa ăn đã lưu',
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            key: ValueKey('learning-day-bar-$index'),
                            width: AppTokens.space24,
                            height: week.counts[index] == 0
                                ? AppTokens.space12
                                : 82 * week.counts[index] / week.maxCount,
                            decoration: BoxDecoration(
                              color: week.counts[index] == 0
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.primary,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTokens.smallRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Row(
          children: [
            for (final label in LearningWeekSummary.dayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LessonCatalogue extends StatelessWidget {
  const _LessonCatalogue({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearningViewModel>();
    final catalog = vm.catalog!;
    final part = catalog.parts.firstWhere(
      (part) => part.id == vm.selectedPartId,
    );
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: 'Bài học nhỏ',
          onBack: vm.isSaving ? null : onBack,
          showBack: true,
        ),
        const SizedBox(height: AppTokens.space24),
        Text(catalog.bookTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppTokens.space8),
        Text(catalog.authors.join(' · '), style: theme.textTheme.bodySmall),
        const SizedBox(height: AppTokens.space8),
        Text(
          '${catalog.parts.length} phần · ${catalog.coreCount} bài học theo mục lục sách',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        if (vm.progressReady)
          Text(
            'Đã đọc ${vm.completedCoreCount}/${catalog.coreCount} bài chính',
            key: const ValueKey('learning-read-count'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        const SizedBox(height: AppTokens.space8),
        Row(
          children: [
            for (final (index, item) in catalog.parts.indexed) ...[
              if (index > 0) const SizedBox(width: AppTokens.space12),
              Expanded(
                child: _PartTab(
                  title: item.displayTitle,
                  selected: item.id == part.id,
                  onTap: vm.isSaving ? null : () => vm.selectPart(item.id),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        Text(
          part.id == 'part-1'
              ? 'PHẦN 1 · 15 CHƯƠNG'
              : 'PHẦN 2 · 12 NHÓM & TỔNG QUAN',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        const _ProgressError(),
        for (final lesson in part.units) ...[
          AppCard(
            key: ValueKey('learning-lesson-${lesson.id}'),
            title: lesson.displayTitle,
            body:
                '${_lessonPosition(lesson)} · Trang ${lesson.printedPage} · '
                '${vm.isRead(lesson.id) ? 'Đã đọc · Đọc lại' : 'Xem bài học'}',
            onTap: vm.isSaving ? null : () => vm.openLesson(lesson.id),
          ),
          const SizedBox(height: AppTokens.space12),
        ],
      ],
    );
  }
}

String _lessonPosition(Lesson lesson) {
  if (!lesson.isCore) return 'Đọc bổ trợ';
  final number = lesson.id.substring(lesson.id.length - 2);
  return '${lesson.partId == 'part-1' ? 'Chương' : 'Nhóm'} $number';
}

class _PartTab extends StatelessWidget {
  const _PartTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTokens.largeRadius),
          border: selected
              ? Border.all(color: theme.colorScheme.primary)
              : null,
          boxShadow: selected ? null : const [AppTokens.cardShadow],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.largeRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space16,
                vertical: AppTokens.space12,
              ),
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonReader extends StatelessWidget {
  const _LessonReader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearningViewModel>();
    final lesson = vm.selectedLesson;
    if (lesson == null) {
      return _LearningFailure(
        message: 'Bài học này không còn trong mục lục.',
        onRetry: vm.showCatalog,
        onBack: onBack,
      );
    }
    final catalog = vm.catalog!;
    final theme = Theme.of(context);
    final read = vm.isRead(lesson.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: 'Chi tiết bài học',
          onBack: vm.isSaving ? null : onBack,
          showBack: true,
        ),
        const SizedBox(height: AppTokens.space24),
        Text(
          '${lesson.partId == 'part-1' ? 'PHẦN 1' : 'PHẦN 2'} · ${_lessonPosition(lesson).toUpperCase()}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Text(lesson.displayTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppTokens.space16),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160),
          child: AppCard(
            title: 'Theo mục lục sách',
            body:
                '${lesson.sourceTitle}\nTrang ${lesson.printedPage} · ${catalog.bookTitle}',
            selected: true,
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Text('Đọc có chủ đích', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTokens.space16),
        Text(lesson.body.summary, style: theme.textTheme.bodyLarge),
        for (final section in lesson.body.sections) ...[
          const SizedBox(height: AppTokens.space16),
          Text(section.heading, style: theme.textTheme.titleLarge),
          for (final paragraph in section.paragraphs) ...[
            const SizedBox(height: AppTokens.space8),
            Text(paragraph, style: theme.textTheme.bodyLarge),
          ],
        ],
        const SizedBox(height: AppTokens.space16),
        Text('Gợi ý suy ngẫm', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTokens.space8),
        Text(lesson.body.reflection, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppTokens.space16),
        Text(
          'Trang đối chiếu: ${lesson.body.sourcePages.map((page) => '${page.printedPage} (PDF ${page.pdfPage})').join(', ')}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Text(
          '${catalog.bookTitle} · ${catalog.authors.join(' và ')}. '
          'Thông tin học tập không thay thế tư vấn y tế.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        const _ProgressError(),
        AppButton(
          key: const ValueKey('learning-mark-read'),
          label: read ? 'Đã đọc' : 'Đánh dấu đã đọc',
          onPressed: read || vm.isLoading || !vm.progressReady
              ? null
              : vm.markSelectedRead,
          isLoading: vm.isSaving,
          loadingLabel: 'Đang lưu tiến độ…',
        ),
        const SizedBox(height: AppTokens.space8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: vm.isSaving ? null : onBack,
            child: const Text('Quay về mục lục'),
          ),
        ),
      ],
    );
  }
}
