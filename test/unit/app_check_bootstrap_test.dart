import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/firebase/app_check_bootstrap.dart';
import 'package:vetalife/services/meal_intelligence.dart';

void main() {
  const androidDebug = AppCheckSettings(
    isWeb: false,
    platform: TargetPlatform.android,
    isDebug: true,
  );
  const androidRelease = AppCheckSettings(
    isWeb: false,
    platform: TargetPlatform.android,
    isDebug: false,
  );

  test('Android debug provider is confined to debug builds', () async {
    expect(androidDebug.usesAndroidDebug, isTrue);
    expect(androidRelease.usesAndroidDebug, isFalse);
    final activated = <AppCheckSettings>[];
    final bootstrap = AppCheckBootstrap(
      settings: androidRelease,
      activate: (settings) async => activated.add(settings),
    );
    await bootstrap.configure();
    await bootstrap.requireAiReady();
    expect(activated, [androidRelease]);
  });

  test(
    'missing web site key leaves non-AI startup usable and blocks AI',
    () async {
      var calls = 0;
      final bootstrap = AppCheckBootstrap(
        settings: const AppCheckSettings(
          isWeb: true,
          platform: TargetPlatform.windows,
          isDebug: true,
        ),
        activate: (_) async {
          calls++;
        },
      );
      await bootstrap.configure();
      await expectLater(
        bootstrap.requireAiReady(),
        throwsA(isA<MealServiceException>()),
      );
      expect(calls, 0);
    },
  );

  test('web debug opt-in cannot run in a release or profile build', () async {
    var calls = 0;
    final bootstrap = AppCheckBootstrap(
      settings: const AppCheckSettings(
        isWeb: true,
        platform: TargetPlatform.windows,
        isDebug: false,
        webSiteKey: 'public-test-site-key',
        webDebug: true,
      ),
      activate: (_) async {
        calls++;
      },
      enableWebDebug: () {
        calls++;
      },
    );
    await expectLater(
      bootstrap.requireAiReady(),
      throwsA(isA<MealServiceException>()),
    );
    expect(calls, 0);
  });

  test(
    'web debug flag is set before SDK activation only after opt-in',
    () async {
      final order = <String>[];
      final bootstrap = AppCheckBootstrap(
        settings: const AppCheckSettings(
          isWeb: true,
          platform: TargetPlatform.windows,
          isDebug: true,
          webSiteKey: 'public-test-site-key',
          webDebug: true,
        ),
        activate: (_) async => order.add('activate'),
        enableWebDebug: () => order.add('debug'),
      );
      await bootstrap.requireAiReady();
      expect(order, ['debug', 'activate']);
    },
  );

  test('release web uses the site key without enabling debug', () async {
    final bootstrap = AppCheckBootstrap(
      settings: const AppCheckSettings(
        isWeb: true,
        platform: TargetPlatform.linux,
        isDebug: false,
        webSiteKey: 'public-test-site-key',
      ),
      activate: (settings) async => expect(settings.usesWebDebug, isFalse),
      enableWebDebug: () => fail('Release must not enable debug'),
    );
    await bootstrap.requireAiReady();
  });

  test('web debug precedes Firebase Core initialization and cached-provider restoration', () async {
    final order = <String>[];
    final bootstrap = AppCheckBootstrap(
      settings: const AppCheckSettings(
        isWeb: true,
        platform: TargetPlatform.windows,
        isDebug: true,
        webSiteKey: 'public-test-site-key',
        webDebug: true,
      ),
      activate: (_) async => order.add('activate'),
      enableWebDebug: () => order.add('debug'),
    );
    await bootstrap.initializeWithFirebase(() async => order.add('firebase'));
    expect(order, ['debug', 'firebase', 'activate']);
    await bootstrap.requireAiReady();
    expect(order, ['debug', 'firebase', 'activate']);
  });

  test('concurrent initialization shares one SDK activation', () async {
    var calls = 0;
    final pending = Completer<void>();
    final bootstrap = AppCheckBootstrap(
      settings: androidDebug,
      activate: (_) {
        calls++;
        return pending.future;
      },
    );
    final first = bootstrap.configure();
    final second = bootstrap.requireAiReady();
    expect(calls, 1);
    pending.complete();
    await Future.wait([first, second]);
  });

  test(
    'activation failure is safe, does not expose internals and can retry',
    () async {
      var calls = 0;
      final bootstrap = AppCheckBootstrap(
        settings: androidDebug,
        activate: (_) async {
          calls++;
          if (calls == 1) throw StateError('private provider details');
        },
      );
      await bootstrap.configure();
      await bootstrap.requireAiReady();
      expect(calls, 2);
    },
  );
}
