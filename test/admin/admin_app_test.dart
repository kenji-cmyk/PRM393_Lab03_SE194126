import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/admin/admin_app.dart';
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
    if (query?.isNotEmpty == true) {
      return AdminUserPage(users: query == alice.email ? [alice] : []);
    }
    return pageToken == null
        ? const AdminUserPage(users: [alice], nextPageToken: 'page-2')
        : const AdminUserPage(users: [bob]);
  }

  @override
  Future<AdminUserDetails> details(String uid) async => AdminUserDetails(
    user: protectedUser ?? (uid == alice.uid ? alice : bob),
    profile: const {'displayName': 'Alice profile', 'goal': 'readDaily'},
    mealCount: 3,
    readLessonCount: 2,
  );
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

void main() {
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
