import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/services/app_telemetry.dart';
import 'package:vetalife/services/auth_service.dart';
import 'package:vetalife/viewmodels/auth_view_model.dart';
import 'package:vetalife/viewmodels/onboarding_view_model.dart';

import 'onboarding_view_model_test.dart' show FakeOnboardingRepository;

class _Telemetry extends AppTelemetry {
  final events = <String>[];
  final operations = <String>[];
  final identities = <String?>[];
  final parameters = <Map<String, Object>>[];
  @override
  Future<void> identify(String? uid) async {
    identities.add(uid);
  }

  @override
  Future<void> event(
    String name, {
    Map<String, Object> parameters = const {},
  }) async {
    events.add(name);
    this.parameters.add(parameters);
  }

  @override
  Future<void> handledError(String operation) async {
    operations.add(operation);
  }
}

class _Auth implements AuthService {
  final stream = StreamController<String?>.broadcast(sync: true);
  bool fail = false;
  @override
  Stream<String?> get userChanges => stream.stream;
  @override
  Future<void> signIn() async {
    if (fail) throw StateError('private payload');
    stream.add('owner');
  }

  @override
  Future<void> signOut() async {
    stream.add(null);
  }
}

void main() {
  test('Firebase adapter strips PII and only accepts bounded counters and fixed enums', () {
    expect(
      FirebaseAppTelemetry.parametersFor('meal_saved', {
        'name': 'private name',
        'notes': 'private notes',
        'item_count': 3,
      }),
      {'flow': 'meal', 'item_count': 3},
    );
    expect(
      FirebaseAppTelemetry.parametersFor('lesson_read', {
        'item_count': -1,
        'lesson_title': 'private text',
      }),
      {'flow': 'learning'},
    );
    expect(
      FirebaseAppTelemetry.parametersFor('login', {'method': 'private text'}),
      {'flow': 'auth', 'method': 'google'},
    );
    expect(FirebaseAppTelemetry.parametersFor('private event', {}), isEmpty);
  });
  test(
    'auth tracks only successful actions and clears identity on signout',
    () async {
      final telemetry = _Telemetry();
      final auth = _Auth();
      final vm = AuthViewModel(auth, telemetry: telemetry)..init();
      addTearDown(() async {
        vm.dispose();
        await auth.stream.close();
      });
      auth.fail = true;
      await vm.signIn();
      expect(telemetry.events, isEmpty);
      expect(telemetry.operations, ['auth']);
      auth.fail = false;
      await vm.signIn();
      await vm.signOut();
      expect(telemetry.identities, ['owner', null]);
      expect(telemetry.events, ['login', 'sign_out']);
      expect(telemetry.parameters, [
        {'method': 'google'},
        {},
      ]);
    },
  );
  test(
    'profile completion event follows persistence, excludes personal data',
    () async {
      final telemetry = _Telemetry();
      final repo = FakeOnboardingRepository()..failSave = true;
      final vm = OnboardingViewModel(repo, telemetry: telemetry);
      addTearDown(vm.dispose);
      await vm.init();
      vm.start();
      vm.updateDisplayName('Private name');
      vm.updateBirthDate('01/01/2000');
      vm.updateWeight('60');
      vm.updateHeight('170');
      vm.continueToGoals();
      await vm.save();
      expect(telemetry.events, ['onboarding_start']);
      repo.failSave = false;
      await vm.save();
      expect(telemetry.events, ['onboarding_start', 'profile_saved']);
      expect(telemetry.parameters.every((p) => p.isEmpty), isTrue);
    },
  );
}
