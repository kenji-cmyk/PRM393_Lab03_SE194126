import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../theme/app_theme.dart';
import 'admin_models.dart';
import 'admin_audit_panel.dart';
import 'admin_journal_panel.dart';
import 'admin_statistics_panel.dart';
import 'admin_services.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({
    super.key,
    required this.sessionService,
    required this.userService,
  });
  final AdminSessionService sessionService;
  final AdminUserService userService;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'VetaLife · Quản trị',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: _AdminGate(sessionService: sessionService, userService: userService),
  );
}

class _AdminGate extends StatefulWidget {
  const _AdminGate({required this.sessionService, required this.userService});
  final AdminSessionService sessionService;
  final AdminUserService userService;

  @override
  State<_AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<_AdminGate> {
  StreamSubscription<AdminIdentity?>? _subscription;
  AdminIdentity? _identity;
  bool _loading = true;
  bool _busy = false;
  bool _blocked = false;
  String? _error;
  int _operation = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.sessionService.sessions.listen(
      (identity) {
        if (!mounted) return;
        setState(() {
          if (_identity?.uid != identity?.uid) {
            _blocked = false;
            _operation++;
            _busy = false;
          }
          _identity = identity;
          _loading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _identity = null;
          _loading = false;
          _blocked = true;
          _error =
              'Không thể xác minh phiên đăng nhập. Vui lòng đăng nhập lại.';
        });
      },
    );
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    final operation = ++_operation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(
          () => _error = 'Chưa thực hiện được. Kiểm tra kết nối hoặc cho phép cửa sổ đăng nhập Google.',
        );
      }
    } finally {
      if (mounted && operation == _operation) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    final uid = _identity?.uid;
    final identity = await widget.sessionService.refresh();
    if (!mounted || _identity?.uid != uid) return;
    setState(() {
      _identity = identity;
      _blocked = false;
    });
  }

  @override
  void dispose() {
    _operation++;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final identity = _identity;
    if (identity != null && identity.isAdmin && !_blocked) {
      return AdminDashboard(
        key: ValueKey(identity.uid),
        identity: identity,
        service: widget.userService,
        onSignOut: () => _perform(widget.sessionService.signOut),
        onForbidden: () {
          if (mounted) setState(() => _blocked = true);
        },
      );
    }
    return Scaffold(
      backgroundColor: AppTokens.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 44,
                      color: AppTokens.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'VetaLife Admin',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      identity == null
                          ? 'Đăng nhập để quản lý người dùng VetaLife.'
                          : 'Bạn chưa có quyền quản trị',
                      textAlign: TextAlign.center,
                    ),
                    if (identity != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        identity.email ?? identity.uid,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chỉ tài khoản được cấp quyền admin bởi người quản lý hệ thống mới truy cập được trang này.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorNotice(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    if (_busy)
                      const CircularProgressIndicator()
                    else if (identity == null)
                      FilledButton.icon(
                        onPressed: () => _perform(widget.sessionService.signIn),
                        icon: const Icon(Icons.login),
                        label: const Text('Đăng nhập Google'),
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => _perform(_refresh),
                            child: const Text('Kiểm tra lại quyền'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _perform(widget.sessionService.signOut),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Action { disable, enable, revoke }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.identity,
    required this.service,
    required this.onSignOut,
    required this.onForbidden,
  });
  final AdminIdentity identity;
  final AdminUserService service;
  final VoidCallback onSignOut;
  final VoidCallback onForbidden;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _search = TextEditingController();
  AdminUserPage? _page;
  String? _query;
  String? _pageToken;
  final List<String?> _previous = [];
  bool _loading = true;
  String? _error;
  int _request = 0;
  int _detailRequest = 0;
  AdminUser? _selected;
  AdminUserDetails? _details;
  bool _detailsLoading = false;
  String? _detailError;
  _Action? _pending;
  bool _acting = false;
  String? _notice;
  int _section = 0;
  AdminUser? _journalUser;
  String? _auditTarget;
  String _localQuery = '';
  String _statusFilter = 'all';
  String _roleFilter = 'all';
  String _verifiedFilter = 'all';
  String _sort = 'name';

  List<AdminUser> get _visibleUsers {
    final needle = _localQuery.trim().toLowerCase();
    final users = (_page?.users ?? const <AdminUser>[])
        .where(
          (user) =>
              (needle.isEmpty ||
                  '${user.label} ${user.email ?? ''} ${user.uid}'
                      .toLowerCase()
                      .contains(needle)) &&
              (_statusFilter == 'all' ||
                  user.disabled == (_statusFilter == 'disabled')) &&
              (_roleFilter == 'all' ||
                  user.isAdmin == (_roleFilter == 'admin')) &&
              (_verifiedFilter == 'all' ||
                  user.emailVerified == (_verifiedFilter == 'verified')),
        )
        .toList();
    users.sort((a, b) {
      if (_sort == 'name') {
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      }
      final av =
          DateTime.tryParse(
            (_sort == 'created' ? a.createdAt : a.lastSignInAt) ?? '',
          )?.millisecondsSinceEpoch ??
          -1;
      final bv =
          DateTime.tryParse(
            (_sort == 'created' ? b.createdAt : b.lastSignInAt) ?? '',
          )?.millisecondsSinceEpoch ??
          -1;
      return bv.compareTo(av);
    });
    return users;
  }

  void _navigate(int section, {String? targetUid}) {
    if (_acting) return;
    setState(() {
      _section = section;
      _auditTarget = targetUid;
    });
  }

  void _openJournal(AdminUser user) {
    if (_acting) return;
    setState(() {
      _journalUser = user;
      _section = 3;
    });
  }

  Future<void> _editName() async {
    final user = _selected;
    if (user == null ||
        _acting ||
        user.isAdmin ||
        user.uid == widget.identity.uid) {
      return;
    }
    var editedName = user.displayName ?? '';
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên hiển thị'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email ?? user.uid),
                  const SizedBox(height: 12),
                  const Text(
                    'Tên tài khoản đăng nhập sẽ được cập nhật. Tên trong hồ sơ sức khỏe được quản lý riêng.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('admin-display-name'),
                    initialValue: editedName,
                    onChanged: (value) => editedName = value,
                    autofocus: true,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Vui lòng nhập tên hiển thị.';
                      if (text.length > 100 ||
                          RegExp(r'[\x00-\x1f\x7f]').hasMatch(text)) {
                        return 'Tên không hợp lệ.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, editedName.trim());
              }
            },
            child: const Text('Xác nhận đổi tên'),
          ),
        ],
      ),
    );
    if (!mounted || name == null || name == user.displayName) return;
    setState(() {
      _acting = true;
      _notice = null;
      _detailError = null;
    });
    try {
      final result = await widget.service.updateDisplayName(user.uid, name);
      if (!mounted) return;
      setState(() => _acting = false);
      await _select(user);
      if (!mounted) return;
      setState(
        () => _notice = result.auditWarning
            ? 'Tên đã được cập nhật. Nhật ký chưa cập nhật trạng thái cuối; không cần thực hiện lại.'
            : 'Đã cập nhật tên hiển thị.',
      );
      await _load();
    } catch (error) {
      if (!mounted || _deny(error)) return;
      setState(() {
        _acting = false;
        _detailError = _message(error);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _message(Object error) => error is AdminApiException
      ? error.message
      : 'Chưa tải được dữ liệu. Vui lòng thử lại.';

  bool _deny(Object error) {
    if (error is AdminApiException && error.isForbidden) {
      widget.onForbidden();
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _page = null;
    });
    try {
      final page = await widget.service.list(
        pageToken: _pageToken,
        query: _query,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request || _deny(error)) return;
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  void _find() {
    if (_acting) return;
    _query = _search.text.trim();
    _previous.clear();
    _pageToken = null;
    _closeDetails();
    _load();
  }

  void _paginate(bool next) {
    if (_acting || _loading) return;
    if (next) {
      final token = _page?.nextPageToken;
      if (token == null) return;
      _previous.add(_pageToken);
      _pageToken = token;
    } else {
      if (_previous.isEmpty) return;
      _pageToken = _previous.removeLast();
    }
    _closeDetails();
    _load();
  }

  void _closeDetails() {
    _detailRequest++;
    setState(() {
      _selected = null;
      _details = null;
      _pending = null;
      _detailError = null;
      _detailsLoading = false;
    });
  }

  Future<void> _select(AdminUser user) async {
    if (_acting) return;
    final request = ++_detailRequest;
    setState(() {
      _selected = user;
      _details = null;
      _pending = null;
      _detailError = null;
      _detailsLoading = true;
      _notice = null;
    });
    try {
      final details = await widget.service.details(user.uid);
      if (!mounted || request != _detailRequest) return;
      setState(() {
        _details = details;
        _selected = details.user;
        _detailsLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _detailRequest || _deny(error)) return;
      setState(() {
        _detailError = _message(error);
        _detailsLoading = false;
      });
    }
  }

  Future<void> _confirm() async {
    final action = _pending;
    final user = _selected;
    if (action == null ||
        user == null ||
        _acting ||
        user.isAdmin ||
        user.uid == widget.identity.uid) {
      return;
    }
    setState(() {
      _acting = true;
      _notice = null;
      _detailError = null;
    });
    try {
      final result = action == _Action.revoke
          ? await widget.service.revokeSessions(user.uid)
          : await widget.service.setDisabled(
              user.uid,
              action == _Action.disable,
            );
      if (!mounted) return;
      setState(() {
        _pending = null;
        _acting = false;
        _notice = result.auditWarning
            ? 'Thao tác đã thành công. Nhật ký chưa cập nhật trạng thái cuối; không cần thực hiện lại.'
            : 'Đã thực hiện thành công.';
      });
      await _select(user);
      if (!mounted) return;
      setState(
        () => _notice = result.auditWarning
            ? 'Thao tác đã thành công. Nhật ký chưa cập nhật trạng thái cuối; không cần thực hiện lại.'
            : 'Đã thực hiện thành công.',
      );
      await _load();
    } catch (error) {
      if (!mounted || _deny(error)) return;
      setState(() {
        _detailError = _message(error);
        _acting = false;
        _pending = null;
      });
    }
  }

  @override
  void dispose() {
    _request++;
    _detailRequest++;
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 1000;
      return Scaffold(
        backgroundColor: AppTokens.canvas,
        body: SafeArea(
          child: Row(
            children: [
              if (desktop) _sidebar(),
              Expanded(
                child: Column(
                  children: [
                    _topbar(desktop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(desktop ? 32 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              switch (_section) {
                                0 => 'Quản lý người dùng',
                                2 => 'Thống kê hoạt động',
                                3 => 'Nhật ký bữa ăn người dùng',
                                _ => 'Nhật ký hệ thống',
                              },
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Theo dõi tài khoản và quản lý quyền truy cập VetaLife.',
                              style: TextStyle(color: AppTokens.secondaryText),
                            ),
                            const SizedBox(height: 24),
                            if (!desktop) ...[
                              _navigation(),
                              const SizedBox(height: 20),
                            ],
                            if (_section == 1)
                              AdminAuditPanel(
                                key: ValueKey(_auditTarget),
                                service: widget.service,
                                onForbidden: widget.onForbidden,
                                targetUid: _auditTarget,
                              ),
                            if (_section == 2)
                              AdminStatisticsPanel(
                                service: widget.service,
                                users: _page?.users ?? const [],
                                pageNumber: _previous.length + 1,
                                onForbidden: widget.onForbidden,
                                onJournal: _openJournal,
                              ),
                            if (_section == 3 && _journalUser != null)
                              AdminJournalPanel(
                                key: ValueKey(_journalUser!.uid),
                                user: _journalUser!,
                                service: widget.service,
                                onForbidden: widget.onForbidden,
                                onBack: () => _navigate(0),
                              ),
                            if (_section == 0) ...[
                              _stats(),
                              const SizedBox(height: 24),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Danh sách tài khoản',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Tìm chính xác theo email hoặc UID. Mỗi trang tối đa 25 tài khoản.',
                                        style: TextStyle(
                                          color: AppTokens.secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: desktop
                                                ? 380
                                                : (constraints.maxWidth - 74)
                                                      .clamp(140, 500)
                                                      .toDouble(),
                                            child: TextField(
                                              key: const ValueKey(
                                                'admin-search',
                                              ),
                                              controller: _search,
                                              enabled: !_acting,
                                              decoration: const InputDecoration(
                                                prefixIcon: Icon(Icons.search),
                                                labelText: 'Email hoặc UID',
                                                border: OutlineInputBorder(),
                                              ),
                                              onSubmitted: (_) => _find(),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: _acting || _loading
                                                ? null
                                                : _find,
                                            icon: const Icon(Icons.search),
                                            label: const Text('Tìm kiếm'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: _acting || _loading
                                                ? null
                                                : () {
                                                    _search.clear();
                                                    _find();
                                                  },
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Làm mới'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _filters(),
                                      const SizedBox(height: 16),
                                      if (_loading)
                                        const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      else if (_error != null)
                                        _ErrorNotice(
                                          message: _error!,
                                          retry: _load,
                                        )
                                      else if (_visibleUsers.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Text(
                                            'Không tìm thấy người dùng phù hợp.',
                                          ),
                                        )
                                      else if (desktop)
                                        _table()
                                      else
                                        ..._visibleUsers.map(_userCard),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text('Trang ${_previous.length + 1}'),
                                          OutlinedButton(
                                            onPressed:
                                                _previous.isEmpty ||
                                                    _loading ||
                                                    _acting
                                                ? null
                                                : () => _paginate(false),
                                            child: const Text('Trang trước'),
                                          ),
                                          OutlinedButton(
                                            onPressed:
                                                _page?.nextPageToken == null ||
                                                    _loading ||
                                                    _acting
                                                ? null
                                                : () => _paginate(true),
                                            child: const Text('Trang tiếp'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selected != null) ...[
                                const SizedBox(height: 24),
                                _detailsCard(),
                              ],
                            ],
                            const SizedBox(height: 20),
                            const Text(
                              'Quyền admin được cấp bởi người quản lý hệ thống qua công cụ quản trị bảo mật. Dashboard không cho phép tự cấp quyền.',
                              style: TextStyle(
                                color: AppTokens.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _sidebar() => Container(
    width: 232,
    color: const Color(0xFF163E2C),
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFFB5DC95), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'VetaLife',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'KHÔNG GIAN QUẢN TRỊ',
          style: TextStyle(
            color: Color(0xFFAFC9B9),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        _navigation(dark: true),
        const Spacer(),
        const Icon(Icons.verified_user_outlined, color: Color(0xFFB5DC95)),
        const SizedBox(height: 12),
        const Text(
          'Quyền truy cập được xác minh tại máy chủ.',
          style: TextStyle(color: Color(0xFFC1D3C7), height: 1.6),
        ),
      ],
    ),
  );

  Widget _topbar(bool desktop) => Container(
    color: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: desktop ? 32 : 16, vertical: 16),
    child: Row(
      children: [
        if (!desktop)
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.eco, color: AppTokens.primary),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VetaLife / Quản trị',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                widget.identity.email ?? 'Quản trị viên',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Đăng xuất'),
        ),
      ],
    ),
  );

  Widget _navigation({bool dark = false}) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final item in [
        (0, Icons.people_outline, 'Người dùng'),
        (2, Icons.bar_chart_outlined, 'Thống kê'),
        (1, Icons.history, 'Nhật ký quản trị'),
      ])
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: dark ? Colors.white : AppTokens.primary,
            backgroundColor: _section == item.$1
                ? (dark
                      ? Colors.white.withValues(alpha: .12)
                      : AppTokens.primaryContainer)
                : null,
          ),
          onPressed: _acting ? null : () => _navigate(item.$1),
          icon: Icon(item.$2),
          label: Text(item.$3),
        ),
    ],
  );

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Lọc và sắp xếp trong trang hiện tại',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 260,
            child: TextFormField(
              key: const ValueKey('admin-local-search'),
              initialValue: _localQuery,
              enabled: !_acting,
              decoration: const InputDecoration(
                labelText: 'Lọc tên, email hoặc UID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _localQuery = value),
            ),
          ),
          _filter('Trạng thái', _statusFilter, {
            'all': 'Tất cả trạng thái',
            'active': 'Đang hoạt động',
            'disabled': 'Đã khóa',
          }, (v) => _statusFilter = v),
          _filter('Vai trò', _roleFilter, {
            'all': 'Tất cả vai trò',
            'admin': 'Admin',
            'user': 'Người dùng',
          }, (v) => _roleFilter = v),
          _filter('Email', _verifiedFilter, {
            'all': 'Mọi email',
            'verified': 'Đã xác minh',
            'unverified': 'Chưa xác minh',
          }, (v) => _verifiedFilter = v),
          _filter('Sắp xếp', _sort, {
            'name': 'Tên A–Z',
            'created': 'Mới đăng ký',
            'signin': 'Đăng nhập gần nhất',
          }, (v) => _sort = v),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Hiển thị ${_visibleUsers.length}/${_page?.users.length ?? 0} tài khoản của trang này. Thống kê phía trên tính trên toàn trang đã tải.',
        style: const TextStyle(color: AppTokens.secondaryText, fontSize: 12),
      ),
    ],
  );

  Widget _filter(
    String label,
    String value,
    Map<String, String> options,
    void Function(String) assign,
  ) => SizedBox(
    width: 200,
    child: DropdownButtonFormField<String>(
      key: ValueKey(
        'admin-filter-${switch (label) {
          'Trạng thái' => 'status',
          'Vai trò' => 'role',
          'Email' => 'verified',
          _ => 'sort',
        }}',
      ),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: _acting
          ? null
          : (v) {
              if (v != null) setState(() => assign(v));
            },
    ),
  );

  Widget _stats() {
    final users = _page?.users ?? const <AdminUser>[];
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _stat('Tài khoản trong trang', users.length, Icons.people_outline),
        _stat(
          'Đang hoạt động',
          users.where((u) => !u.disabled).length,
          Icons.check_circle_outline,
        ),
        _stat(
          'Đã khóa',
          users.where((u) => u.disabled).length,
          Icons.lock_outline,
        ),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon) => Container(
    width: 220,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppTokens.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTokens.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTokens.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _loading ? '—' : '$value',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _status(AdminUser user) => Chip(
    label: Text(
      user.disabled ? 'Đã khóa' : 'Hoạt động',
      style: TextStyle(
        fontSize: 12,
        color: user.disabled ? Colors.red.shade800 : AppTokens.primary,
      ),
    ),
    backgroundColor: user.disabled
        ? const Color(0xFFFFE9E5)
        : AppTokens.primaryContainer,
    side: BorderSide.none,
  );

  Widget _table() => SizedBox(
    width: double.infinity,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(AppTokens.canvas),
        columns: const [
          DataColumn(label: Text('Người dùng')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Vai trò')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Chi tiết')),
        ],
        rows: _visibleUsers
            .map(
              (user) => DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(user.label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        user.email ?? 'Chưa có email',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(user.isAdmin ? 'Admin' : 'Người dùng')),
                  DataCell(_status(user)),
                  DataCell(
                    SizedBox(
                      width: 144,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _acting ? null : () => _select(user),
                            child: const Text('Xem'),
                          ),
                          IconButton(
                            tooltip: 'Xem nhật ký bữa ăn',
                            onPressed: _acting
                                ? null
                                : () => _openJournal(user),
                            icon: const Icon(Icons.restaurant_menu),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _userCard(AdminUser user) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: AppTokens.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          user.email ?? user.uid,
          style: const TextStyle(color: AppTokens.secondaryText),
        ),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _status(user),
            Text(user.isAdmin ? 'Admin' : 'Người dùng'),
            TextButton(
              onPressed: _acting ? null : () => _select(user),
              child: const Text('Xem'),
            ),
            TextButton.icon(
              onPressed: _acting ? null : () => _openJournal(user),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Xem nhật ký bữa ăn'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _detailsCard() {
    final user = _selected!;
    final protected = user.isAdmin || user.uid == widget.identity.uid;
    final profile = _details?.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chi tiết tài khoản',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng chi tiết',
                  onPressed: _acting ? null : _closeDetails,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              user.label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            _field('UID', user.uid),
            _field('Email', user.email ?? 'Chưa có email'),
            _field(
              'Xác minh email',
              user.emailVerified ? 'Đã xác minh' : 'Chưa xác minh',
            ),
            _field('Ngày tạo', _date(user.createdAt)),
            _field('Đăng nhập gần nhất', _date(user.lastSignInAt)),
            if (_detailsLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (_detailError != null)
              _ErrorNotice(
                message: _detailError!,
                retry: _acting ? null : () => _select(user),
              ),
            if (_details != null) ...[
              const Divider(height: 32),
              Text(
                'Hồ sơ và hoạt động',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (profile == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Người dùng chưa hoàn tất hồ sơ.'),
                )
              else ...[
                _field('Tên hồ sơ', '${profile['displayName'] ?? '—'}'),
                _field('Ngày sinh', '${profile['birthDate'] ?? '—'}'),
                _field(
                  'Cân nặng / chiều cao',
                  '${profile['weightKg'] ?? '—'} kg / ${profile['heightCm'] ?? '—'} cm',
                ),
                _field('Mục tiêu', _goal(profile['goal'])),
              ],
              _field('Bữa ăn đã lưu', '${_details!.mealCount}'),
              _field('Bài học đã đọc', '${_details!.readLessonCount}'),
            ],
            const Divider(height: 32),
            if (protected)
              const Text(
                'Tài khoản quản trị và tài khoản của bạn được bảo vệ. Không thể khóa hoặc thu hồi phiên tại đây.',
                style: TextStyle(color: AppTokens.secondaryText),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _acting || _detailsLoading || _details == null
                        ? null
                        : _editName,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Đổi tên hiển thị'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _acting || _detailsLoading || _details == null
                        ? null
                        : () => setState(
                            () => _pending = user.disabled
                                ? _Action.enable
                                : _Action.disable,
                          ),
                    icon: Icon(
                      user.disabled ? Icons.lock_open : Icons.lock_outline,
                    ),
                    label: Text(
                      user.disabled ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _acting || _detailsLoading || _details == null
                        ? null
                        : () => setState(() => _pending = _Action.revoke),
                    icon: const Icon(Icons.phonelink_erase),
                    label: const Text('Thu hồi phiên đăng nhập'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _acting ? null : () => _openJournal(user),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Xem nhật ký bữa ăn'),
            ),
            TextButton.icon(
              onPressed: _acting
                  ? null
                  : () => _navigate(1, targetUid: user.uid),
              icon: const Icon(Icons.history),
              label: const Text('Xem nhật ký tài khoản'),
            ),
            if (_pending != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('admin-confirmation'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTokens.peach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pending == _Action.revoke
                          ? 'Thu hồi mọi phiên đăng nhập của tài khoản này?'
                          : _pending == _Action.disable
                          ? 'Khóa quyền đăng nhập của tài khoản này?'
                          : 'Cho phép tài khoản này đăng nhập trở lại?',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pending == _Action.revoke
                          ? 'Người dùng sẽ cần đăng nhập lại khi làm mới phiên. Phiên hiện tại có thể còn hiệu lực đến khi ID token hết hạn.'
                          : 'Dữ liệu hồ sơ, bữa ăn và tiến độ học được giữ nguyên.',
                    ),
                    const SizedBox(height: 12),
                    if (_acting)
                      const CircularProgressIndicator()
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: _confirm,
                            child: const Text('Xác nhận'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _pending = null),
                            child: const Text('Hủy'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _notice!,
                    style: const TextStyle(color: AppTokens.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Wrap(
      spacing: 8,
      children: [
        Text('$label:', style: const TextStyle(color: AppTokens.secondaryText)),
        SelectableText(value),
      ],
    ),
  );
  String _goal(Object? value) => switch (value) {
    'addVegetables' => 'Thêm rau vào bữa ăn',
    'recordMeals' => 'Ghi lại bữa ăn',
    'readDaily' => 'Đọc mỗi ngày',
    _ => '—',
  };
  String _date(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    return date == null
        ? 'Chưa có'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
