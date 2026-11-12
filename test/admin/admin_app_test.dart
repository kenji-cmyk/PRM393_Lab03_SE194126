import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/admin/admin_app.dart';
import 'package:vetalife/admin/admin_audit_panel.dart';
import 'package:vetalife/admin/admin_models.dart';
import 'package:vetalife/admin/admin_services.dart';

const admin = AdminIdentity(
  uid: 'admin-1',
  email: 'admin@example.test',
  isAdmin: true,
);
const alice = AdminUser(
  uid: 'alice',
  email: 'alice@example.test',
  displayName: 'Alice',
);
const bob = AdminUser(
  uid: 'bob',
  email: 'bob@example.test',
  displayName: 'Bob',
);

class FakeSession implements AdminSessionService {
  FakeSession(this.identity);
  AdminIdentity? identity;
  final controller = StreamController<AdminIdentity?>.broadcast();
  int signIns = 0;
  int signOuts = 0;
  @override
  Stream<AdminIdentity?> get sessions async* {
    yield identity;
    yield* controller.stream;
  }

  void emit(AdminIdentity? value) {
    identity = value;
    controller.add(value);
  }

  @override
  Future<void> signIn() async {
    signIns++;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    emit(null);
  }

  @override
  Future<AdminIdentity?> refresh() async => identity;
}

class FakeUsers implements AdminUserService {
  final calls = <({String? token, String? query})>[];
  final changes = <({String uid, bool disabled})>[];
  final revocations = <String>[];
  final nameChanges = <({String uid, String displayName})>[];
  final auditCalls = <({String? token, String? targetUid})>[];
  final journalCalls = <({String uid, String? token})>[];
  final detailCalls = <String>[];
  final detailFailures = <String>{};
  int statisticsCalls = 0;
  bool failJournal = false;
  bool denyJournal = false;
  bool emptyJournal = false;
  bool failStatistics = false;
  bool denyStatistics = false;
  bool incompleteStatistics = false;
  List<AdminUser>? fixtureUsers;
  bool failNameUpdate = false;
  bool failAudit = false;
  bool denyAudit = false;
  String? updatedName;
  bool failList = false;
  bool denyList = false;
  bool auditWarning = false;
  AdminUser? protectedUser;
  Completer<AdminUserPage>? pendingList;
  @override
  Future<AdminUserPage> list({String? pageToken, String? query}) async {
    calls.add((token: pageToken, query: query));
    if (denyList) throw const AdminApiException('permission-denied');
    if (failList) throw const AdminApiException('unavailable');
    if (pendingList != null) return pendingList!.future;
    if (protectedUser != null) return AdminUserPage(users: [protectedUser!]);
    if (fixtureUsers != null) return AdminUserPage(users: fixtureUsers!);
    if (query?.isNotEmpty == true) {
      return AdminUserPage(users: query == alice.email ? [alice] : []);
    }
    return pageToken == null
        ? const AdminUserPage(users: [alice], nextPageToken: 'page-2')
        : const AdminUserPage(users: [bob]);
  }

  @override
  Future<AdminUserDetails> details(String uid) async {
    detailCalls.add(uid);
    if (detailFailures.contains(uid)) {
      throw const AdminApiException('unavailable');
    }
    return AdminUserDetails(
      user:
          protectedUser ??
          (uid == alice.uid
              ? AdminUser(
                  uid: alice.uid,
                  email: alice.email,
                  displayName: updatedName ?? alice.displayName,
                )
              : bob),
      profile: const {'displayName': 'Alice profile', 'goal': 'readDaily'},
      mealCount: uid == alice.uid ? 3 : 8,
      readLessonCount: uid == alice.uid ? 2 : 4,
    );
  }

  @override
  Future<AdminJournalPage> journal(String uid, {String? pageToken}) async {
    journalCalls.add((uid: uid, token: pageToken));
    if (denyJournal) throw const AdminApiException('permission-denied');
    if (failJournal) throw const AdminApiException('unavailable');
    return AdminJournalPage(
      meals: emptyJournal
          ? []
          : [
              AdminJournalMeal(
                id: pageToken == null ? 'meal-1' : 'meal-2',
                name: pageToken == null ? 'Cơm rau Alice' : 'Cháo đậu Alice',
                mealType: pageToken == null ? 'lunch' : 'breakfast',
                eatenAt: '2026-11-12T05:30:00.000Z',
                notes: 'Ít muối',
                ingredientCount: 3,
              ),
            ],
      nextPageToken: !emptyJournal && pageToken == null ? 'meal-page-2' : null,
    );
  }

  @override
  Future<AdminStatistics> statistics() async {
    statisticsCalls++;
    if (denyStatistics) throw const AdminApiException('permission-denied');
    if (failStatistics) throw const AdminApiException('unavailable');
    return AdminStatistics(
      scannedUsers: 123,
      isComplete: !incompleteStatistics,
      active: 117,
      disabled: 6,
      admins: 2,
      verified: 98,
      newUsers7d: 9,
      newUsers30d: 18,
      signedIn7d: 37,
      signedIn30d: 69,
      generatedAt: '2026-11-12T05:30:00.000Z',
    );
  }

  @override
  Future<AdminActionResult> setDisabled(String uid, bool disabled) async {
    changes.add((uid: uid, disabled: disabled));
    return AdminActionResult(auditWarning: auditWarning);
  }

  @override
  Future<AdminActionResult> revokeSessions(String uid) async {
    revocations.add(uid);
    return const AdminActionResult();
  }

  @override
  Future<AdminActionResult> updateDisplayName(
    String uid,
    String displayName,
  ) async {
    nameChanges.add((uid: uid, displayName: displayName));
    if (failNameUpdate) throw const AdminApiException('unavailable');
    updatedName = displayName;
    return AdminActionResult(auditWarning: auditWarning);
  }

  @override
  Future<AdminAuditPage> auditLogs({
    String? pageToken,
    String? targetUid,
  }) async {
    auditCalls.add((token: pageToken, targetUid: targetUid));
    if (denyAudit) throw const AdminApiException('permission-denied');
    if (failAudit) throw const AdminApiException('unavailable');
    return AdminAuditPage(
      order: targetUid == null ? 'newest' : 'record-id',
      logs: [
        AdminAuditEntry(
          id: pageToken == null ? 'log-1' : 'log-2',
          actorUid: admin.uid,
          targetUid: targetUid ?? (pageToken == null ? alice.uid : bob.uid),
          action: pageToken == null ? 'disable-user' : 'enable-user',
          status: 'completed',
          createdAt: '2026-11-12T01:00:00.000Z',
        ),
      ],
      nextPageToken: pageToken == null ? 'audit-page-2' : null,
    );
  }
}

Future<void> mount(
  WidgetTester tester,
  FakeSession session,
  FakeUsers users,
) async {
  addTearDown(session.controller.close);
  await tester.pumpWidget(
    AdminApp(sessionService: session, userService: users),
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String key, String label) async {
  final dropdown = find.byKey(ValueKey(key));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('user meal journal opens for selected UID and paginates meals', (
    tester,
  ) async {
    final users = FakeUsers();
    await mount(tester, FakeSession(admin), users);
    await tapText(tester, 'Xem nhật ký bữa ăn');
    expect(users.journalCalls, [(uid: 'alice', token: null)]);
    expect(find.text('Cơm rau Alice'), findsOneWidget);
    expect(find.textContaining('Ít muối'), findsOneWidget);
    await tapText(tester, 'Bữa ăn tiếp');
    expect(users.journalCalls.last, (uid: 'alice', token: 'meal-page-2'));
    expect(find.text('Cháo đậu Alice'), findsOneWidget);
    expect(find.text('Cơm rau Alice'), findsNothing);
    await tapText(tester, 'Bữa ăn trước');
    expect(users.journalCalls.last, (uid: 'alice', token: null));
    expect(find.text('Cơm rau Alice'), findsOneWidget);
    expect(users.auditCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('journal errors retry and denied access removes private meals', (
    tester,
  ) async {
    final users = FakeUsers()..failJournal = true;
    await mount(tester, FakeSession(admin), users);
    await tapText(tester, 'Xem nhật ký bữa ăn');
    expect(find.text('Cơm rau Alice'), findsNothing);
    expect(
      find.textContaining('Chưa kết nối được dịch vụ quản trị'),
      findsOneWidget,
    );
    users.failJournal = false;
    await tapText(tester, 'Thử lại');
    expect(find.text('Cơm rau Alice'), findsOneWidget);
    users.denyJournal = true;
    await tapText(tester, 'Tải lại bữa ăn');
    expect(find.text('Bạn chưa có quyền quản trị'), findsOneWidget);
    expect(find.text('Cơm rau Alice'), findsNothing);
  });

  testWidgets('empty meal journal is shown as empty with no next page', (
    tester,
  ) async {
    final users = FakeUsers()..emptyJournal = true;
    await mount(tester, FakeSession(admin), users);
    await tapText(tester, 'Xem nhật ký bữa ăn');
    expect(find.text('Người dùng chưa có bữa ăn đã lưu.'), findsOneWidget);
    final next = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Bữa ăn tiếp'),
    );
    expect(next.onPressed, isNull);
    expect(find.text('Cơm rau Alice'), findsNothing);
  });

  testWidgets('statistics loads account metrics and activity only on request', (
    tester,
  ) async {
    final users = FakeUsers()..fixtureUsers = const [alice, bob];
    await mount(tester, FakeSession(admin), users);
    expect(users.statisticsCalls, 0);
    expect(users.detailCalls, isEmpty);
    await tapText(tester, 'Thống kê');
    expect(users.statisticsCalls, 1);
    expect(find.text('123'), findsOneWidget);
    expect(users.detailCalls, isEmpty);
    await tapText(tester, 'Tải thống kê hoạt động');
    expect(users.detailCalls, unorderedEquals(['alice', 'bob']));
    expect(users.calls, hasLength(1));
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);
    expect(find.text('Bữa ăn: 3 · Bài đã đọc: 2'), findsOneWidget);
    expect(find.text('Bữa ăn: 8 · Bài đã đọc: 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'statistics row failure remains visible instead of a zero count',
    (tester) async {
      final users = FakeUsers()
        ..fixtureUsers = const [alice, bob]
        ..detailFailures.add('bob');
      await mount(tester, FakeSession(admin), users);
      await tapText(tester, 'Thống kê');
      await tapText(tester, 'Tải thống kê hoạt động');
      expect(users.detailCalls, unorderedEquals(['alice', 'bob']));
      expect(
        find.textContaining('Chưa kết nối được dịch vụ quản trị'),
        findsWidgets,
      );
      expect(find.text('3'), findsWidgets);
      expect(find.text('8'), findsNothing);
      expect(
        find.text('Bữa ăn: Lỗi tải · Bài đã đọc: Lỗi tải'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('360px journal and statistics controls stay usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final users = FakeUsers();
    await mount(tester, FakeSession(admin), users);
    await tapText(tester, 'Xem nhật ký bữa ăn');
    await tapText(tester, 'Bữa ăn tiếp');
    expect(find.text('Cháo đậu Alice'), findsOneWidget);
    await tapText(tester, 'Thống kê');
    await tapText(tester, 'Tải thống kê hoạt động');
    expect(users.detailCalls, contains('alice'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'statistics summary retries and incomplete scope is explicit before denial',
    (tester) async {
      final users = FakeUsers()
        ..failStatistics = true
        ..incompleteStatistics = true;
      await mount(tester, FakeSession(admin), users);
      await tapText(tester, 'Thống kê');
      expect(find.text('123'), findsNothing);
      expect(
        find.textContaining('Chưa kết nối được dịch vụ quản trị'),
        findsOneWidget,
      );
      users.failStatistics = false;
      await tapText(tester, 'Thử lại');
      expect(find.text('123'), findsOneWidget);
      expect(find.textContaining('chưa phải toàn bộ hệ thống'), findsOneWidget);
      expect(users.detailCalls, isEmpty);
      users.denyStatistics = true;
      await tapText(tester, 'Làm mới tổng quan');
      expect(find.text('Bạn chưa có quyền quản trị'), findsOneWidget);
      expect(find.text('123'), findsNothing);
    },
  );

  testWidgets(
    'desktop statistics table links the chosen account to its meals',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final users = FakeUsers()..fixtureUsers = const [alice, bob];
      await mount(tester, FakeSession(admin), users);
      expect(
        tester.takeException(),
        isNull,
        reason: 'initial desktop users layout',
      );
      await tapText(tester, 'Thống kê');
      expect(
        tester.takeException(),
        isNull,
        reason: 'desktop statistics summary',
      );
      await tapText(tester, 'Tải thống kê hoạt động');
      expect(
        tester.takeException(),
        isNull,
        reason: 'desktop statistics table',
      );
      expect(find.byType(DataTable), findsOneWidget);
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows, hasLength(2));
      expect((table.rows[0].cells[2].child as Text).data, '3');
      expect((table.rows[1].cells[2].child as Text).data, '8');
      final bobLink = find.widgetWithText(TextButton, 'Xem bữa ăn').last;
      await tester.ensureVisible(bobLink);
      await tester.tap(bobLink);
      await tester.pumpAndSettle();
      expect(users.journalCalls.last.uid, 'bob');
      expect(find.text('Nhật ký bữa ăn · Bob'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local search text and filtered list survive section navigation',
    (tester) async {
      final users = FakeUsers()..fixtureUsers = const [alice, bob];
      await mount(tester, FakeSession(admin), users);
      final search = find.byKey(const ValueKey('admin-local-search'));
      await tester.enterText(search, 'Ali');
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      await tapText(tester, 'Nhật ký quản trị');
      expect(find.text('Mã nhật ký: log-1'), findsOneWidget);
      await tapText(tester, 'Người dùng');
      final editable = tester.widget<EditableText>(
        find.descendant(of: search, matching: find.byType(EditableText)),
      );
      expect(editable.controller.text, 'Ali');
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      await tester.enterText(search, 'Bob');
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Bob',
        ),
        findsOneWidget,
      );
      expect(users.calls, hasLength(1));
    },
  );

  testWidgets(
    '360px admin edit and audit navigation remain usable and denial removes data',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final users = FakeUsers();
      await mount(tester, FakeSession(admin), users);
      await tapText(tester, 'Xem');
      await tapText(tester, 'Đổi tên hiển thị');
      await tester.enterText(
        find.byKey(const ValueKey('admin-display-name')),
        'Alice nhỏ',
      );
      await tapText(tester, 'Xác nhận đổi tên');
      expect(users.updatedName, 'Alice nhỏ');
      await tapText(tester, 'Nhật ký quản trị');
      expect(find.text('Mã nhật ký: log-1'), findsOneWidget);
      await tapText(tester, 'Nhật ký tiếp');
      expect(find.text('Mã nhật ký: log-2'), findsOneWidget);
      users.denyAudit = true;
      await tapText(tester, 'Tải lại nhật ký');
      expect(find.text('Bạn chưa có quyền quản trị'), findsOneWidget);
      expect(find.text('Mã nhật ký: log-2'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('page filters combine and sorting uses actual creation dates', (
    tester,
  ) async {
    final users = FakeUsers()
      ..fixtureUsers = const [
        AdminUser(
          uid: 'z',
          displayName: 'Zelda',
          emailVerified: true,
          createdAt: '2026-11-12T00:00:00Z',
        ),
        AdminUser(
          uid: 'a',
          displayName: 'Anna',
          disabled: true,
          createdAt: '2025-01-01T00:00:00Z',
        ),
        AdminUser(
          uid: 'm',
          displayName: 'Manager',
          isAdmin: true,
          emailVerified: true,
        ),
      ];
    await mount(tester, FakeSession(admin), users);
    expect(
      tester.getTopLeft(find.text('Anna')).dy,
      lessThan(tester.getTopLeft(find.text('Zelda')).dy),
    );
    await choose(tester, 'admin-filter-sort', 'Mới đăng ký');
    expect(
      tester.getTopLeft(find.text('Zelda')).dy,
      lessThan(tester.getTopLeft(find.text('Anna')).dy),
    );
    await choose(tester, 'admin-filter-status', 'Đang hoạt động');
    expect(find.text('Anna'), findsNothing);
    await choose(tester, 'admin-filter-role', 'Người dùng');
    expect(find.text('Manager'), findsNothing);
    expect(find.text('Zelda'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('admin-local-search')),
      'no match',
    );
    await tester.pumpAndSettle();
    expect(find.text('Zelda'), findsNothing);
    expect(users.calls, hasLength(1));
  });

  testWidgets(
    'display name edit validates before sending and trims confirmed value',
    (tester) async {
      final users = FakeUsers();
      await mount(tester, FakeSession(admin), users);
      await tapText(tester, 'Xem');
      await tapText(tester, 'Đổi tên hiển thị');
      await tester.enterText(
        find.byKey(const ValueKey('admin-display-name')),
        '   ',
      );
      await tapText(tester, 'Xác nhận đổi tên');
      expect(users.nameChanges, isEmpty);
      expect(find.text('Vui lòng nhập tên hiển thị.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-display-name')),
        '  Alice mới  ',
      );
      await tapText(tester, 'Xác nhận đổi tên');
      expect(users.nameChanges, [(uid: 'alice', displayName: 'Alice mới')]);
      expect(find.text('Đã cập nhật tên hiển thị.'), findsOneWidget);
      expect(find.text('Alice mới'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed name save reports failure without success notice', (
    tester,
  ) async {
    final users = FakeUsers()..failNameUpdate = true;
    await mount(tester, FakeSession(admin), users);
    await tapText(tester, 'Xem');
    await tapText(tester, 'Đổi tên hiển thị');
    await tester.enterText(
      find.byKey(const ValueKey('admin-display-name')),
      'Alice mới',
    );
    await tapText(tester, 'Xác nhận đổi tên');
    expect(
      find.textContaining('Chưa kết nối được dịch vụ quản trị'),
      findsOneWidget,
    );
    expect(find.text('Đã cập nhật tên hiển thị.'), findsNothing);
    expect(users.updatedName, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'audit pagination preserves UID filter and reset returns first page',
    (tester) async {
      final users = FakeUsers();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminAuditPanel(service: users, onForbidden: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mã nhật ký: log-1'), findsOneWidget);
      await tapText(tester, 'Nhật ký tiếp');
      expect(users.auditCalls.last, (token: 'audit-page-2', targetUid: null));
      expect(find.text('Mã nhật ký: log-2'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-audit-target')),
        '  alice  ',
      );
      await tapText(tester, 'Lọc nhật ký');
      expect(users.auditCalls.last, (token: null, targetUid: 'alice'));
      expect(find.text('Trang nhật ký 1'), findsOneWidget);
      expect(
        find.textContaining('theo mã bản ghi, không theo thời gian'),
        findsOneWidget,
      );
      await tapText(tester, 'Nhật ký tiếp');
      expect(users.auditCalls.last, (
        token: 'audit-page-2',
        targetUid: 'alice',
      ));
      await tapText(tester, 'Tất cả nhật ký');
      expect(users.auditCalls.last, (token: null, targetUid: null));
      expect(
        find.textContaining('theo mã bản ghi, không theo thời gian'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('audit failures can retry and denied reads close admin access', (
    tester,
  ) async {
    final users = FakeUsers()..failAudit = true;
    var forbidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminAuditPanel(
              service: users,
              onForbidden: () => forbidden = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Chưa kết nối được dịch vụ quản trị'),
      findsOneWidget,
    );
    users.failAudit = false;
    await tapText(tester, 'Thử lại');
    expect(find.text('Mã nhật ký: log-1'), findsOneWidget);
    users.denyAudit = true;
    await tester.ensureVisible(find.text('Tải lại nhật ký'));
    await tester.tap(find.text('Tải lại nhật ký'));
    await tester.pump();
    expect(forbidden, isTrue);
    expect(find.text('Mã nhật ký: log-1'), findsNothing);
  });

  testWidgets('other admin accounts are protected from dashboard mutations', (
    tester,
  ) async {
    final users = FakeUsers()
      ..protectedUser = const AdminUser(
        uid: 'other-admin',
        displayName: 'Other admin',
        isAdmin: true,
      );
    await mount(tester, FakeSession(admin), users);
    await tapText(tester, 'Xem');
    expect(
      find.textContaining(
        'Tài khoản quản trị và tài khoản của bạn được bảo vệ',
      ),
      findsOneWidget,
    );
    expect(find.text('Khóa tài khoản'), findsNothing);
    expect(find.text('Thu hồi phiên đăng nhập'), findsNothing);
    expect(users.changes, isEmpty);
    expect(users.revocations, isEmpty);
  });

  testWidgets('signed out and ordinary users cannot request admin data', (
    tester,
  ) async {
    final session = FakeSession(null);
    final users = FakeUsers();
    await mount(tester, session, users);
    expect(find.text('Đăng nhập Google'), findsOneWidget);
    expect(users.calls, isEmpty);
    await tapText(tester, 'Đăng nhập Google');
    expect(session.signIns, 1);
    session.emit(const AdminIdentity(uid: 'ordinary', isAdmin: false));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có quyền quản trị'), findsOneWidget);
    expect(users.calls, isEmpty);
    await tapText(tester, 'Đăng xuất');
    expect(find.text('Đăng nhập Google'), findsOneWidget);
  });

  testWidgets('admin can paginate then search with pagination reset', (
    tester,
  ) async {
    final users = FakeUsers();
    await mount(tester, FakeSession(admin), users);
    expect(find.text('Alice'), findsOneWidget);
    await tapText(tester, 'Trang tiếp');
    expect(users.calls.last.token, 'page-2');
    expect(find.text('Bob'), findsOneWidget);
    await tapText(tester, 'Trang trước');
    expect(users.calls.last.token, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('admin-search')),
      '  alice@example.test  ',
    );
    await tapText(tester, 'Tìm kiếm');
    expect(users.calls.last.query, 'alice@example.test');
    expect(users.calls.last.token, isNull);
    expect(find.text('Trang 1'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('admin-search')),
      'missing',
    );
    await tapText(tester, 'Tìm kiếm');
    expect(find.text('Không tìm thấy người dùng phù hợp.'), findsOneWidget);
  });

  testWidgets(
    'failed list has retry and denied API removes protected dashboard',
    (tester) async {
      final users = FakeUsers()..failList = true;
      await mount(tester, FakeSession(admin), users);
      expect(
        find.textContaining('Chưa kết nối được dịch vụ quản trị'),
        findsOneWidget,
      );
      users.failList = false;
      await tapText(tester, 'Thử lại');
      expect(find.text('Alice'), findsOneWidget);
      users.denyList = true;
      await tapText(tester, 'Làm mới');
      expect(find.text('Bạn chưa có quyền quản trị'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
    },
  );

  testWidgets(
    'mutations require confirmation and cancellation has no side effects',
    (tester) async {
      final users = FakeUsers()..auditWarning = true;
      await mount(tester, FakeSession(admin), users);
      await tapText(tester, 'Xem');
      expect(find.text('Alice profile'), findsOneWidget);
      await tapText(tester, 'Khóa tài khoản');
      expect(users.changes, isEmpty);
      await tapText(tester, 'Hủy');
      expect(users.changes, isEmpty);
      await tapText(tester, 'Khóa tài khoản');
      await tapText(tester, 'Xác nhận');
      expect(users.changes, [(uid: 'alice', disabled: true)]);
      expect(find.textContaining('không cần thực hiện lại'), findsOneWidget);
      await tapText(tester, 'Thu hồi phiên đăng nhập');
      expect(users.revocations, isEmpty);
      await tapText(tester, 'Xác nhận');
      expect(users.revocations, ['alice']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('360px layout and large text keep controls reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FakeSession(admin);
    final users = FakeUsers();
    addTearDown(session.controller.close);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: AdminApp(sessionService: session, userService: users),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Xem');
    await tapText(tester, 'Khóa tài khoản');
    await tapText(tester, 'Hủy');
    expect(tester.takeException(), isNull);
  });

  testWidgets('signout drops private view and late results cannot reappear', (
    tester,
  ) async {
    final session = FakeSession(admin);
    final users = FakeUsers();
    await mount(tester, session, users);
    await tapText(tester, 'Xem');
    expect(find.text('Alice profile'), findsOneWidget);
    users.pendingList = Completer<AdminUserPage>();
    await tester.ensureVisible(find.text('Làm mới'));
    await tester.tap(find.text('Làm mới'));
    await tester.pump();
    session.emit(null);
    await tester.pumpAndSettle();
    users.pendingList!.complete(const AdminUserPage(users: [bob]));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập Google'), findsOneWidget);
    expect(find.text('Alice profile'), findsNothing);
    expect(find.text('Bob'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
