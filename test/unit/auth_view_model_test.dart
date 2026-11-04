import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/services/auth_service.dart';
import 'package:vetalife/viewmodels/auth_view_model.dart';

class _Auth implements AuthService {
  final changes = StreamController<String?>.broadcast(sync: true);
  Object? signInError;
  Object? signOutError;
  Completer<void>? gate;
  int attempts = 0;

  @override
  Stream<String?> get userChanges => changes.stream;

  @override
  Future<void> signIn() async {
    attempts++;
    if (gate != null) await gate!.future;
    if (signInError != null) throw signInError!;
    changes.add('owner-a');
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    changes.add(null);
  }
}

void main() {
  late _Auth service;
  late AuthViewModel vm;

  setUp(() {
    service = _Auth();
    vm = AuthViewModel(service)..init();
  });
  tearDown(() async {
    vm.dispose();
    await service.changes.close();
  });

  test(
    'session stream routes signed out and restores the authenticated UID',
    () {
      expect(vm.isLoading, isTrue);
      service.changes.add(null);
      expect(vm.isLoading, isFalse);
      expect(vm.uid, isNull);
      service.changes.add('owner-b');
      expect(vm.uid, 'owner-b');
    },
  );

  test('cancelled sign in is visible and permits retry', () async {
    service.signInError = const SignInCancelled();
    await vm.signIn();
    expect(vm.errorMessage, contains('hủy đăng nhập'));
    expect(vm.isBusy, isFalse);
    expect(vm.uid, isNull);
    service.signInError = null;
    await vm.signIn();
    expect(vm.uid, 'owner-a');
    expect(vm.errorMessage, isNull);
  });

  test('pending sign in does not launch a second Google operation', () async {
    service.gate = Completer<void>();
    final first = vm.signIn();
    await vm.signIn();
    expect(service.attempts, 1);
    expect(vm.isBusy, isTrue);
    service.gate!.complete();
    await first;
    expect(vm.isBusy, isFalse);
    expect(vm.uid, 'owner-a');
  });

  test(
    'failed sign out retains session and supports another attempt',
    () async {
      service.changes.add('owner-a');
      service.signOutError = StateError('offline');
      await vm.signOut();
      expect(vm.uid, 'owner-a');
      expect(vm.errorMessage, contains('Chưa đăng xuất'));
      service.signOutError = null;
      await vm.signOut();
      expect(vm.uid, isNull);
      expect(vm.errorMessage, isNull);
    },
  );

  test('sign in failure never exposes backend exception data', () async {
    service.signInError = StateError('private backend payload');
    await vm.signIn();
    expect(vm.errorMessage, contains('Đăng nhập chưa thành công'));
    expect(vm.errorMessage, isNot(contains('private backend payload')));
    expect(vm.uid, isNull);
    expect(vm.isBusy, isFalse);
  });
}
