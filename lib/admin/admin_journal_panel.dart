import 'package:flutter/material.dart';

import 'admin_models.dart';
import 'admin_services.dart';

class AdminJournalPanel extends StatefulWidget {
  const AdminJournalPanel({
    super.key,
    required this.user,
    required this.service,
    required this.onForbidden,
    required this.onBack,
  });
  final AdminUser user;
  final AdminUserService service;
  final VoidCallback onForbidden;
  final VoidCallback onBack;

  @override
  State<AdminJournalPanel> createState() => _AdminJournalPanelState();
}

class _AdminJournalPanelState extends State<AdminJournalPanel> {
  AdminJournalPage? _page;
  AdminUserDetails? _details;
  String? _error;
  String? _countError;
  String? _token;
  final List<String?> _previous = [];
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCounts();
  }

  bool _denied(Object error) {
    if (error is AdminApiException && error.isForbidden) {
      widget.onForbidden();
      return true;
    }
    return false;
  }

  Future<void> _loadCounts() async {
    try {
      final details = await widget.service.details(widget.user.uid);
      if (!mounted) return;
      setState(() => _details = details);
    } catch (error) {
      if (!mounted || _denied(error)) return;
      setState(() => _countError = 'Chưa tải được tổng số bữa ăn và bài học.');
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _page = null;
    });
    try {
      final page = await widget.service.journal(
        widget.user.uid,
        pageToken: _token,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request || _denied(error)) return;
      setState(() {
        _loading = false;
        _error = error is AdminApiException
            ? error.message
            : 'Chưa tải được nhật ký bữa ăn.';
      });
    }
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('admin-journal'),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhật ký bữa ăn · ${widget.user.label}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SelectableText('UID: ${widget.user.uid}'),
          const SizedBox(height: 8),
          const Text(
            'Các bữa ăn người dùng đã lưu, mới nhất trước. Lịch sử thao tác của quản trị viên nằm ở mục Nhật ký quản trị.',
          ),
          const SizedBox(height: 16),
          if (_details != null)
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text('Tổng bữa ăn: ${_details!.mealCount}'),
                Text('Bài học đã đọc: ${_details!.readLessonCount}'),
              ],
            ),
          if (_countError != null) Text(_countError!),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại bữa ăn'),
              ),
              TextButton(
                onPressed: widget.onBack,
                child: const Text('Quay lại người dùng'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          else if (_page?.meals.isEmpty != false)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Người dùng chưa có bữa ăn đã lưu.'),
            )
          else
            ..._page!.meals.map(
              (meal) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(_type(meal.mealType)),
                        Text(_date(meal.eatenAt)),
                        Text('${meal.ingredientCount} nguyên liệu'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(meal.notes.isEmpty ? 'Không có ghi chú.' : meal.notes),
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
              Text('Trang bữa ăn ${_previous.length + 1}'),
              OutlinedButton(
                onPressed: _loading || _previous.isEmpty
                    ? null
                    : () {
                        _token = _previous.removeLast();
                        _load();
                      },
                child: const Text('Bữa ăn trước'),
              ),
              OutlinedButton(
                onPressed: _loading || _page?.nextPageToken == null
                    ? null
                    : () {
                        _previous.add(_token);
                        _token = _page!.nextPageToken;
                        _load();
                      },
                child: const Text('Bữa ăn tiếp'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _type(String value) => switch (value) {
    'breakfast' => 'Bữa sáng',
    'lunch' => 'Bữa trưa',
    'dinner' => 'Bữa tối',
    'snack' => 'Bữa phụ',
    _ => 'Bữa ăn',
  };
  String _date(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Chưa có thời gian';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
