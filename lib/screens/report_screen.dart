import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../viewmodels/report_view_model.dart';
import '../widgets/app_components.dart';

/// The caller owns the view model and disposes it when the account changes.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.viewModel});
  final ReportViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final vm = viewModel;
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
                      const Text('Vị trí lưu riêng tư:'),
                      SelectableText(vm.uploaded!.storageUri),
                    ],
                    if (vm.canOpen || vm.isOpening) ...[
                      const SizedBox(height: AppTokens.space24),
                      AppButton(
                        label: 'Mở PDF',
                        onPressed: vm.open,
                        isLoading: vm.isOpening,
                        loadingLabel: 'Đang mở PDF…',
                      ),
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
