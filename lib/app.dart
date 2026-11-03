import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/flow_screen.dart';
import 'services/app_dependencies.dart';
import 'services/auth_service.dart';
import 'services/local_onboarding_repository.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/onboarding_view_model.dart';
import 'widgets/app_components.dart';

class NepLanhApp extends StatelessWidget {
  const NepLanhApp({super.key, this.isPreview = true});
  final bool isPreview;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nếp Lành',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: isPreview ? const _PreviewFlow() : const _CloudBootstrap(),
  );
}

class _PreviewFlow extends StatelessWidget {
  const _PreviewFlow();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => OnboardingViewModel(LocalOnboardingRepository())..init(),
    child: Builder(
      builder: (context) => FlowScreen(
        isPreview: true,
        onSignOut: context.read<OnboardingViewModel>().clearPreviewSession,
      ),
    ),
  );
}

class _CloudBootstrap extends StatefulWidget {
  const _CloudBootstrap();

  @override
  State<_CloudBootstrap> createState() => _CloudBootstrapState();
}

class _CloudBootstrapState extends State<_CloudBootstrap> {
  late Future<AuthService> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = AppDependencies.initializeCloud();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthService>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: AppErrorState(
              message:
                  'Chưa kết nối được Firebase. Hoàn tất flutterfire configure '
                  'theo docs/firebase-setup.md rồi chạy lại ứng dụng.',
              onRetry: () => setState(() {
                _initialization = AppDependencies.initializeCloud();
              }),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: SafeArea(child: AppLoadingState()));
      }
      return ChangeNotifierProvider(
        create: (_) => AuthViewModel(snapshot.data!)..init(),
        child: const _AuthGate(),
      );
    },
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.isLoading) {
      return const Scaffold(body: SafeArea(child: AppLoadingState()));
    }
    final uid = auth.uid;
    if (uid == null) return const _SignInScreen();
    return ChangeNotifierProvider(
      key: ValueKey(uid),
      create: (_) =>
          OnboardingViewModel(AppDependencies.repositoryFor(uid))..init(),
      child: Column(
        children: [
          if (auth.errorMessage != null)
            SafeArea(
              bottom: false,
              child: AppInlineError(message: auth.errorMessage!),
            ),
          Expanded(
            child: FlowScreen(isPreview: false, onSignOut: auth.signOut),
          ),
        ],
      ),
    );
  }
}

class _SignInScreen extends StatelessWidget {
  const _SignInScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.pageInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTokens.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark()),
                  const SizedBox(height: AppTokens.space24),
                  Text(
                    'Chào mừng đến Nếp Lành',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'Đăng nhập để lưu hồ sơ và mục tiêu của riêng bạn.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space32),
                  if (auth.errorMessage != null) ...[
                    AppInlineError(message: auth.errorMessage!),
                    const SizedBox(height: AppTokens.space16),
                  ],
                  AppButton(
                    label: 'Đăng nhập với Google',
                    onPressed: auth.signIn,
                    isLoading: auth.isBusy,
                    loadingLabel: 'Đang đăng nhập…',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
