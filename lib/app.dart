import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/flow_screen.dart';
import 'services/app_dependencies.dart';
import 'services/auth_service.dart';
import 'services/local_onboarding_repository.dart';
import 'services/book_meal_intelligence.dart';
import 'services/local_meal_repository.dart';
import 'services/meal_photo_picker.dart';
import 'services/local_lesson_progress_repository.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/onboarding_view_model.dart';
import 'viewmodels/meal_view_model.dart';
import 'viewmodels/learning_view_model.dart';
import 'widgets/app_components.dart';

class VetaLifeApp extends StatelessWidget {
  const VetaLifeApp({
    super.key,
    this.isPreview = true,
    this.previewPreferences,
  });
  final bool isPreview;

  /// Optional preview storage injection; cloud composition never uses it.
  final SharedPreferencesAsync? previewPreferences;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'VetaLife',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: isPreview
        ? _PreviewFlow(preferences: previewPreferences)
        : const _CloudBootstrap(),
  );
}

class _PreviewFlow extends StatefulWidget {
  const _PreviewFlow({this.preferences});
  final SharedPreferencesAsync? preferences;

  @override
  State<_PreviewFlow> createState() => _PreviewFlowState();
}

class _PreviewFlowState extends State<_PreviewFlow> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => OnboardingViewModel(
          LocalOnboardingRepository(preferences: widget.preferences),
        )..init(),
      ),
      ChangeNotifierProvider(
        create: (context) => MealViewModel(
          repository: LocalMealRepository(preferences: widget.preferences),
          intelligence: BookMealIntelligence(),
          photoPicker: DeviceMealPhotoPicker(preferences: widget.preferences),
          profile: () => context.read<OnboardingViewModel>().profile,
        )..initialize(),
      ),
      ChangeNotifierProvider(
        create: (_) => LearningViewModel(
          repository: LocalLessonProgressRepository(
            preferences: widget.preferences,
          ),
        )..initialize(),
      ),
    ],
    child: Builder(
      builder: (context) => PopScope(
        canPop: !_isSigningOut,
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: _isSigningOut,
              child: ExcludeFocus(
                excluding: _isSigningOut,
                child: ExcludeSemantics(
                  excluding: _isSigningOut,
                  child: FlowScreen(
                    isPreview: true,
                    onSignOut: () async {
                      if (_isSigningOut) return;
                      final meals = context.read<MealViewModel>();
                      final onboarding = context.read<OnboardingViewModel>();
                      final learning = context.read<LearningViewModel>();
                      if (meals.isSaving || learning.isSaving) return;
                      setState(() => _isSigningOut = true);
                      try {
                        await learning.clearPreviewSession();
                        await meals.clearPreviewSession();
                        await onboarding.clearPreviewSession();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Chưa xóa được dữ liệu xem thử. Hãy thử đăng xuất lại.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSigningOut = false);
                      }
                    },
                  ),
                ),
              ),
            ),
            if (_isSigningOut)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppTokens.canvas,
                  child: SafeArea(
                    child: AppLoadingState(message: 'Đang đăng xuất…'),
                  ),
                ),
              ),
          ],
        ),
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
    return MultiProvider(
      key: ValueKey(uid),
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              OnboardingViewModel(AppDependencies.repositoryFor(uid))..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => MealViewModel(
            repository: AppDependencies.mealsFor(uid),
            intelligence: AppDependencies.mealIntelligence(),
            photoPicker: DeviceMealPhotoPicker(sessionOwner: 'cloud:$uid'),
            profile: () => context.read<OnboardingViewModel>().profile,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              LearningViewModel(repository: AppDependencies.lessonsFor(uid))
                ..initialize(),
        ),
      ],
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
                    'Chào mừng đến VetaLife',
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
