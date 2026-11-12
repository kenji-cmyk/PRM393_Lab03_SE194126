import 'dart:async';

import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/report_view_model.dart';
import '../widgets/app_components.dart';

/// The caller owns the view model and disposes it when the account changes.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.viewModel});
  final ReportViewModel viewModel;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.viewModel, widget.viewModel)) _loadHistory();
  }

  void _loadHistory() {
    final model = widget.viewModel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(model, widget.viewModel)) {
        unawaited(model.loadHistory());
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final vm = widget.viewModel;
      return PopScope(
        canPop: !vm.isBusy && !vm.isOpening,
        child: Scaffold(
          appBar: AppBar(title: const Text('Báo cáo cá nhân')),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTokens.contentMaxWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppTokens.pageInset),
                  children: [
                    Text(
                      'Xuất hồ sơ, bữa ăn đã lưu và các bài đánh dấu đã đọc thành PDF.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTokens.space16),
                    Text(
                      vm.isPreview
                          ? 'Chế độ xem thử: PDF chỉ được tạo trên thiết bị, không tải lên cloud.'
                          : 'Báo cáo chứa thông tin cá nhân. Chỉ tài khoản của bạn được đọc báo cáo trên cloud. Khi lưu hoặc chia sẻ PDF từ hộp thoại, bạn tự chọn nơi nhận.',
                    ),
                    const SizedBox(height: AppTokens.space24),
                    AppButton(
                      label: vm.isPreview
                          ? 'Tạo PDF xem thử'
                          : 'Tạo và lưu PDF lên cloud',
                      onPressed: vm.isOpening ? null : vm.generate,
                      isLoading: vm.isBusy,
                      loadingLabel: 'Đang xử lý…',
                    ),
                    if (vm.isBusy) ...[
                      const SizedBox(height: AppTokens.space16),
                      LinearProgressIndicator(
                        value: vm.progress > 0 ? vm.progress : null,
                        semanticsLabel: 'Tiến độ tải báo cáo',
                      ),
                      TextButton(
                        onPressed: vm.cancel,
                        child: const Text('Hủy thao tác'),
                      ),
                    ],
                    if (vm.message != null) ...[
                      const SizedBox(height: AppTokens.space16),
                      Semantics(liveRegion: true, child: Text(vm.message!)),
                    ],
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: AppTokens.space16),
                      AppInlineError(message: vm.errorMessage!),
                    ],
                    if (vm.uploaded != null) ...[
                      const SizedBox(height: AppTokens.space16),
                      const Text(
                        'Báo cáo đã được lưu riêng tư cho tài khoản của bạn.',
                      ),
                    ],
                    if (vm.hasGeneratedReport) ...[
                      const SizedBox(height: AppTokens.space24),
                      AppButton(
                        label: 'Mở PDF',
                        onPressed: vm.isBusy || vm.isOpening ? null : vm.open,
                        isLoading:
                            vm.isOpening &&
                            vm.openingReportPath == vm.uploaded?.path,
                        loadingLabel: 'Đang mở PDF…',
                      ),
                    ],
                    if (vm.supportsHistory) ...[
                      const SizedBox(height: AppTokens.space24),
                      _ReportHistory(viewModel: vm),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ReportHistory extends StatelessWidget {
  const _ReportHistory({required this.viewModel});
  final ReportViewModel viewModel;

  String _date(DateTime date) {
    final value = date.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';

  Widget _report(BuildContext context, SavedReport saved, int position) {
    final vm = viewModel;
    final opening = vm.isOpening && vm.openingReportPath == saved.report.path;
    final label = 'Báo cáo ${position + 1} · ${_date(saved.createdAt)}';
    return Card(
      key: ValueKey('saved-report-${saved.report.path}'),
      margin: const EdgeInsets.only(bottom: AppTokens.space16),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('PDF · ${_size(saved.sizeBytes)} · Chỉ bạn được truy cập'),
            const SizedBox(height: 8),
            TextButton.icon(
              key: ValueKey('open-saved-${saved.report.path}'),
              onPressed: vm.isBusy || vm.isOpening
                  ? null
                  : () => vm.openSaved(saved),
              icon: opening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(opening ? 'Đang mở báo cáo…' : 'Mở báo cáo đã lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Báo cáo đã lưu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('10 báo cáo gần nhất của tài khoản hiện tại.'),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: vm.historyLoading || vm.isBusy || vm.isOpening
                ? null
                : vm.loadHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới danh sách'),
          ),
        ),
        if (vm.historyLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(
              semanticsLabel: 'Đang tải báo cáo đã lưu',
            ),
          ),
        if (vm.historyError != null) ...[
          AppInlineError(message: vm.historyError!),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: vm.historyLoading ? null : vm.loadHistory,
              child: const Text('Thử tải lại báo cáo'),
            ),
          ),
        ],
        if (!vm.historyLoading && vm.historyError == null && vm.history.isEmpty)
          const Text(
            'Chưa có báo cáo đã lưu. Tạo báo cáo đầu tiên ở phía trên.',
          ),
        for (var index = 0; index < vm.history.length; index++)
          _report(context, vm.history[index], index),
      ],
    );
  }
}
