import 'package:flutter/material.dart';

import 'admin_models.dart';
import 'admin_services.dart';

class AdminStatisticsPanel extends StatefulWidget {
  const AdminStatisticsPanel({
    super.key,
    required this.service,
    required this.users,
    required this.pageNumber,
    required this.onForbidden,
    required this.onJournal,
  });
  final AdminUserService service;
  final List<AdminUser> users;
  final int pageNumber;
  final VoidCallback onForbidden;
  final ValueChanged<AdminUser> onJournal;

  @override
  State<AdminStatisticsPanel> createState() => _AdminStatisticsPanelState();
}

class _AdminStatisticsPanelState extends State<AdminStatisticsPanel> {
  AdminStatistics? _summary;
  bool _loading = true;
  bool _activityLoading = false;
  bool _activityRequested = false;
  String? _error;
  final Map<String, AdminUserDetails> _details = {};
  final Map<String, String> _rowErrors = {};
  int _request = 0;
  int _activityRequest = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _deny(Object error) {
    if (error is AdminApiException && error.isForbidden) {
      widget.onForbidden();
      return true;
    }
    return false;
  }

  String _message(Object error) => error is AdminApiException
      ? error.message
      : 'Chưa tải được thống kê. Vui lòng thử lại.';

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
    });
    try {
      final summary = await widget.service.statistics();
      if (!mounted || request != _request) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request || _deny(error)) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _loadActivity() async {
    if (_activityLoading) return;
    final request = ++_activityRequest;
    final users = widget.users.take(25).toList();
    setState(() {
      _activityLoading = true;
      _activityRequested = true;
      _details.clear();
      _rowErrors.clear();
    });
    var next = 0;
    var denied = false;
    Future<void> worker() async {
      while (mounted &&
          request == _activityRequest &&
          !denied &&
          next < users.length) {
        final user = users[next++];
        try {
          final details = await widget.service.details(user.uid);
          if (!mounted || request != _activityRequest || denied) return;
          setState(() => _details[user.uid] = details);
        } catch (error) {
          if (!mounted || request != _activityRequest || denied) return;
          if (error is AdminApiException && error.isForbidden) {
            denied = true;
            widget.onForbidden();
            return;
          }
          setState(() => _rowErrors[user.uid] = _message(error));
        }
      }
    }

    await Future.wait(List.generate(users.length.clamp(0, 4), (_) => worker()));
    if (mounted && request == _activityRequest && !denied) {
      setState(() => _activityLoading = false);
    }
  }

  @override
  void dispose() {
    _request++;
    _activityRequest++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('admin-statistics'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng quan tài khoản',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Các mốc 7 và 30 ngày dựa trên thời điểm tạo tài khoản và đăng nhập gần nhất, không phải số lần mở ứng dụng.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới tổng quan'),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ] else if (_summary case final summary?) ...[
                Text(
                  summary.isComplete
                      ? 'Phạm vi: toàn bộ ${summary.scannedUsers} tài khoản tại thời điểm tải.'
                      : 'Phạm vi: ${summary.scannedUsers} tài khoản đã quét; chưa phải toàn bộ hệ thống.',
                  key: const ValueKey('admin-statistics-scope'),
                ),
                const SizedBox(height: 8),
                Text('Cập nhật: ${_date(summary.generatedAt)}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric('Tài khoản đã thống kê', summary.scannedUsers),
                    _metric('Được phép đăng nhập', summary.active),
                    _metric('Tài khoản bị khóa', summary.disabled),
                    _metric('Quản trị viên', summary.admins),
                    _metric('Email đã xác minh', summary.verified),
                    _metric(
                      'Email chưa xác minh',
                      summary.scannedUsers - summary.verified,
                    ),
                    _metric('Tài khoản mới · 7 ngày', summary.newUsers7d),
                    _metric('Tài khoản mới · 30 ngày', summary.newUsers30d),
                    _metric('Đăng nhập gần đây · 7 ngày', summary.signedIn7d),
                    _metric('Đăng nhập gần đây · 30 ngày', summary.signedIn30d),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bảng hoạt động người dùng',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Phạm vi: ${widget.users.take(25).length} tài khoản trong trang người dùng ${widget.pageNumber} đã tải. Đổi trang hoặc tìm email/UID ở mục Người dùng để xem nhóm khác.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('admin-load-activity'),
                onPressed: _activityLoading || widget.users.isEmpty
                    ? null
                    : _loadActivity,
                icon: const Icon(Icons.query_stats),
                label: Text(
                  _activityLoading
                      ? 'Đang tải hoạt động…'
                      : 'Tải thống kê hoạt động',
                ),
              ),
              if (_activityLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              if (!_activityRequested)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nhấn tải thống kê để lấy số bữa ăn, bài học và tình trạng hồ sơ từ máy chủ.',
                  ),
                ),
              if (_activityRequested) ...[
                const SizedBox(height: 16),
                Text(
                  'Đã tải ${_details.length}/${widget.users.take(25).length} tài khoản; ${_rowErrors.length} tài khoản chưa tải được.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric(
                      'Bữa ăn · nhóm đã tải',
                      _details.values.fold(0, (sum, d) => sum + d.mealCount),
                    ),
                    _metric(
                      'Bài học · nhóm đã tải',
                      _details.values.fold(
                        0,
                        (sum, d) => sum + d.readLessonCount,
                      ),
                    ),
                    _metric(
                      'Có hồ sơ · nhóm đã tải',
                      _details.values.where((d) => d.profile != null).length,
                    ),
                    _metric(
                      'Có ghi bữa ăn · nhóm đã tải',
                      _details.values.where((d) => d.mealCount > 0).length,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tổng hoạt động chỉ tính những tài khoản đã tải thành công; lỗi không được tính là 0.',
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 800
                      ? _table()
                      : Column(
                          children: widget.users
                              .take(25)
                              .map(_userCard)
                              .toList(),
                        ),
                ),
              ],
              if (widget.users.isEmpty)
                const Text(
                  'Chưa có tài khoản trong trang này. Quay lại Người dùng để tải hoặc thử lại danh sách.',
                ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _metric(String label, int value) => Container(
    width: 205,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer
          .withValues(alpha: .25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
      ],
    ),
  );

  String _count(AdminUser user, bool meals) {
    final details = _details[user.uid];
    if (details != null) {
      return '${meals ? details.mealCount : details.readLessonCount}';
    }
    return _rowErrors.containsKey(user.uid) ? 'Lỗi tải' : 'Đang tải';
  }

  Widget _table() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Người dùng')),
        DataColumn(label: Text('Trạng thái')),
        DataColumn(label: Text('Bữa ăn'), numeric: true),
        DataColumn(label: Text('Bài đã đọc'), numeric: true),
        DataColumn(label: Text('Hồ sơ')),
        DataColumn(label: Text('Nhật ký')),
      ],
      rows: widget.users
          .take(25)
          .map(
            (user) => DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email ?? user.uid,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(user.disabled ? 'Đã khóa' : 'Hoạt động')),
                DataCell(Text(_count(user, true))),
                DataCell(Text(_count(user, false))),
                DataCell(
                  _rowErrors.containsKey(user.uid)
                      ? Tooltip(
                          message: _rowErrors[user.uid]!,
                          child: const Text('Chưa tải được'),
                        )
                      : Text(
                          _details.containsKey(user.uid)
                              ? (_details[user.uid]!.profile == null
                                    ? 'Chưa có'
                                    : 'Đã có')
                              : 'Đang tải',
                        ),
                ),
                DataCell(
                  TextButton(
                    onPressed: () => widget.onJournal(user),
                    child: const Text('Xem bữa ăn'),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );

  Widget _userCard(AdminUser user) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(user.email ?? user.uid),
        Text(user.disabled ? 'Đã khóa' : 'Hoạt động'),
        Text(
          'Bữa ăn: ${_count(user, true)} · Bài đã đọc: ${_count(user, false)}',
        ),
        if (_rowErrors[user.uid] case final error?)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_details[user.uid] case final details?)
          Text(details.profile == null ? 'Chưa có hồ sơ' : 'Đã có hồ sơ'),
        TextButton(
          onPressed: () => widget.onJournal(user),
          child: const Text('Xem bữa ăn'),
        ),
      ],
    ),
  );

  String _date(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Chưa có';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
