import 'package:flutter/material.dart';

import 'admin_models.dart';
import 'admin_services.dart';

class AdminAuditPanel extends StatefulWidget {
  const AdminAuditPanel({
    super.key,
    required this.service,
    required this.onForbidden,
    this.targetUid,
  });
  final AdminUserService service;
  final VoidCallback onForbidden;
  final String? targetUid;

  @override
  State<AdminAuditPanel> createState() => _AdminAuditPanelState();
}

class _AdminAuditPanelState extends State<AdminAuditPanel> {
  late final TextEditingController _target;
  AdminAuditPage? _page;
  final List<String?> _previous = [];
  String? _token;
  String? _filter;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _target = TextEditingController(text: widget.targetUid);
    _filter = widget.targetUid;
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _page = null;
    });
    try {
      final page = await widget.service.auditLogs(
        pageToken: _token,
        targetUid: _filter,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      if (error is AdminApiException && error.isForbidden) {
        widget.onForbidden();
        return;
      }
      setState(() {
        _loading = false;
        _error = error is AdminApiException
            ? error.message
            : 'Chưa tải được nhật ký. Vui lòng thử lại.';
      });
    }
  }

  void _find() {
    if (_loading) return;
    final value = _target.text.trim();
    _filter = value.isEmpty ? null : value;
    _token = null;
    _previous.clear();
    _load();
  }

  @override
  void dispose() {
    _request++;
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhật ký quản trị',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Theo dõi thao tác của quản trị viên, tài khoản liên quan và kết quả. Nhật ký bữa ăn nằm ở mục Người dùng.',
          ),
          const SizedBox(height: 8),
          Text(
            _page?.order == 'record-id' || (_page == null && _filter != null)
                ? 'Lịch sử theo tài khoản được phân trang theo mã bản ghi, không theo thời gian.'
                : 'Toàn bộ lịch sử quản trị: mới nhất trước.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: TextField(
                  key: const ValueKey('admin-audit-target'),
                  controller: _target,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'UID tài khoản liên quan',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _find(),
                ),
              ),
              FilledButton(
                onPressed: _loading ? null : _find,
                child: const Text('Lọc nhật ký'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại nhật ký'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        _target.clear();
                        _find();
                      },
                child: const Text('Tất cả nhật ký'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ] else if (_page?.logs.isEmpty != false)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Chưa có nhật ký phù hợp.'),
            )
          else
            ..._page!.logs.map(
              (entry) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          _action(entry.action),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(_status(entry.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText('Quản trị viên: ${entry.actorUid}'),
                    SelectableText('Tài khoản: ${entry.targetUid}'),
                    Text('Thời gian: ${_date(entry.createdAt)}'),
                    const SizedBox(height: 4),
                    SelectableText(
                      'Mã nhật ký: ${entry.id}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Trang nhật ký ${_previous.length + 1}'),
              OutlinedButton(
                onPressed: _loading || _previous.isEmpty
                    ? null
                    : () {
                        _token = _previous.removeLast();
                        _load();
                      },
                child: const Text('Nhật ký trước'),
              ),
              OutlinedButton(
                onPressed: _loading || _page?.nextPageToken == null
                    ? null
                    : () {
                        _previous.add(_token);
                        _token = _page!.nextPageToken;
                        _load();
                      },
                child: const Text('Nhật ký tiếp'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _action(String value) => switch (value) {
    'disable-user' => 'Khóa tài khoản',
    'enable-user' => 'Mở khóa tài khoản',
    'revoke-sessions' => 'Thu hồi phiên đăng nhập',
    'update-display-name' => 'Đổi tên hiển thị',
    _ => value,
  };
  String _status(String value) => switch (value) {
    'completed' => 'Thành công',
    'failed' => 'Thất bại',
    'attempted' => 'Đã ghi nhận yêu cầu',
    _ => value,
  };
  String _date(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) return 'Chưa có';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }
}
