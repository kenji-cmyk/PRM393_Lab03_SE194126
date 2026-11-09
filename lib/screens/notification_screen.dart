import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/notification_view_model.dart';
import '../widgets/app_components.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.onOpen});
  final ValueChanged<NotificationDestination> onOpen;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationViewModel>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTokens.contentMaxWidth,
            ),
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTokens.pageInset),
                children: [
                  Text(switch (vm.permission) {
                    NotificationPermission.granted =>
                      'Đã cho phép nhận thông báo.',
                    NotificationPermission.denied => 'Bạn đã từ chối thông báo. Có thể đổi quyền trong cài đặt ứng dụng hoặc trình duyệt.',
                    NotificationPermission.unsupported =>
                      'Thiết bị này chưa hỗ trợ thông báo đẩy.',
                    NotificationPermission.notDetermined =>
                      'Bật thông báo để nhận lời nhắc và xem lại tại đây.',
                  }),
                  const SizedBox(height: AppTokens.space16),
                  if (vm.permission != NotificationPermission.unsupported)
                    AppButton(
                      label: vm.permission == NotificationPermission.granted
                          ? 'Kiểm tra kết nối thông báo'
                          : 'Bật thông báo',
                      onPressed: vm.enable,
                      isLoading: vm.isBusy,
                      loadingLabel: 'Đang kết nối…',
                    ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: AppTokens.space16),
                    AppInlineError(message: vm.errorMessage!),
                    TextButton(
                      onPressed: vm.initialize,
                      child: const Text('Thử lại'),
                    ),
                  ],
                  const SizedBox(height: AppTokens.space24),
                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (vm.items.isEmpty)
                    const Text(
                      'Chưa có thông báo. Thông báo nhận được sẽ xuất hiện tại đây.',
                    )
                  else
                    for (final item in vm.items)
                      Card(
                        child: ListTile(
                          minVerticalPadding: AppTokens.space12,
                          leading: Icon(
                            item.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                          ),
                          title: Text(
                            item.title.isEmpty ? 'VetaLife' : item.title,
                          ),
                          subtitle: Text(item.body),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: vm.isBusy
                              ? null
                              : () async {
                                  await vm.open(item);
                                  if (!context.mounted) return;
                                  final destination = vm.takeDestination();
                                  if (destination != null) {
                                    widget.onOpen(destination);
                                  }
                                },
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
