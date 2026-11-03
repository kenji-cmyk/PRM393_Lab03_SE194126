import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nep_lanh/app.dart';
import 'package:nep_lanh/models/user_profile.dart';
import 'package:nep_lanh/screens/flow_screen.dart';
import 'package:nep_lanh/services/onboarding_repository.dart';
import 'package:nep_lanh/theme/app_theme.dart';
import 'package:nep_lanh/viewmodels/onboarding_view_model.dart';
import 'package:provider/provider.dart';

class _UnavailableProfile implements OnboardingRepository {
  @override
  Future<UserProfile?> load() async => throw StateError('permission-denied');
  @override
  Future<void> save(UserProfile profile) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('cloud load error still permits sign out and account switching', (
    tester,
  ) async {
    final vm = OnboardingViewModel(_UnavailableProfile());
    addTearDown(vm.dispose);
    await vm.init();
    var signOuts = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: FlowScreen(isPreview: false, onSignOut: () => signOuts++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Đăng xuất'));
    expect(signOuts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cloud mode reports missing configuration without using preview',
    (tester) async {
      await tester.pumpWidget(const NepLanhApp(isPreview: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa kết nối được Firebase'), findsOneWidget);
      expect(find.textContaining('Bản xem thử'), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
