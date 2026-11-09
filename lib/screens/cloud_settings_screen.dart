import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/app_telemetry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class CloudSettingsScreen extends StatelessWidget {
  const CloudSettingsScreen({
    super.key,
    required this.settings,
    this.telemetry = const NoopAppTelemetry(),
    required this.isPreview,
  });
  final AppSettings settings;
  final AppTelemetry telemetry;
  final bool isPreview;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt ứng dụng')),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(AppTokens.pageInset),
          children: [
            Text(
              isPreview
                  ? 'Chế độ xem thử: dùng cấu hình mặc định.'
                  : 'Cấu hình được đồng bộ từ máy chủ khi tải lại.',
            ),
            const SizedBox(height: AppTokens.space16),
            ListTile(
              title: const Text('Nội dung học'),
              subtitle: Text(settings.learningEnabled ? 'Đang mở' : 'Tạm đóng'),
            ),
            ListTile(
              title: const Text('Xuất báo cáo'),
              subtitle: Text(
                settings.reportExportEnabled ? 'Đang mở' : 'Tạm đóng',
              ),
            ),
            if (settings.errorMessage != null)
              AppInlineError(message: settings.errorMessage!),
            if (!isPreview)
              AppButton(
                label: 'Tải lại cấu hình',
                onPressed: settings.refresh,
                isLoading: settings.isLoading,
                loadingLabel: 'Đang tải cấu hình…',
              ),
            if (!isPreview &&
                telemetry is FirebaseAppTelemetry &&
                (telemetry as FirebaseAppTelemetry).canTestCrash) ...[
              const Divider(),
              TextButton(
                onPressed: () async {
                  await telemetry.handledError('diagnostic_handled');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi lỗi kiểm thử đã xử lý.'),
                      ),
                    );
                  }
                },
                child: const Text('Gửi lỗi kiểm thử đã xử lý'),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Kiểm thử Crashlytics'),
                      content: const Text(
                        'Ứng dụng sẽ dừng. Mở lại ứng dụng để gửi báo cáo lỗi.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Dừng ứng dụng'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    (telemetry as FirebaseAppTelemetry).testCrash();
                  }
                },
                child: const Text('Tạo crash kiểm thử'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
