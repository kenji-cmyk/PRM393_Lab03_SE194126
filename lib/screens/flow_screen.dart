import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_goal.dart';
import 'meal_flow_screen.dart';
import 'learning_flow_screen.dart';
import '../theme/app_theme.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../viewmodels/meal_view_model.dart';
import '../viewmodels/learning_view_model.dart';
import '../widgets/app_components.dart';
import '../widgets/meal_navigation.dart';

/// Flow 1: welcome → personal information → goal → persisted home.
class FlowScreen extends StatelessWidget {
  const FlowScreen({
    super.key,
    required this.onSignOut,
    required this.isPreview,
  });

  final VoidCallback onSignOut;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();
    final meals = context.watch<MealViewModel?>();
    final learning = context.watch<LearningViewModel?>();
    if (vm.stage == OnboardingStage.home &&
        meals != null &&
        meals.stage != MealStage.home) {
      return MealFlowScreen(
        onHome: meals.showHome,
        onProgress: learning == null
            ? null
            : () {
                if (meals.isSaving) return;
                meals.showHome();
                learning.showProgress();
              },
        onLearn: learning == null
            ? null
            : () {
                if (meals.isSaving) return;
                meals.showHome();
                learning.showCatalog();
              },
      );
    }
    if (vm.stage == OnboardingStage.home &&
        learning != null &&
        learning.stage != LearningStage.home) {
      return LearningFlowScreen(
        onHome: learning.showHome,
        onJournal: () {
          if (learning.isSaving) return;
          learning.showHome();
          meals?.openJournal();
        },
      );
    }
    final interceptBack =
        vm.stage == OnboardingStage.profile ||
        vm.stage == OnboardingStage.goals;
    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !vm.isSaving) vm.back();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: vm.stage != OnboardingStage.home,
          child: switch (vm.stage) {
            OnboardingStage.loading => const AppLoadingState(),
            OnboardingStage.welcome => WelcomeScreen(isPreview: isPreview),
            OnboardingStage.profile => const UserProfileScreen(),
            OnboardingStage.goals => const GoalSetupScreen(),
            OnboardingStage.home => HomeScreen(
              onSignOut: onSignOut,
              isPreview: isPreview,
            ),
            OnboardingStage.error => AppErrorState(
              message:
                  vm.errorMessage ?? 'Vui lòng kiểm tra kết nối và thử lại.',
              onRetry: vm.init,
            ),
          },
        ),
        bottomNavigationBar: vm.stage == OnboardingStage.home
            ? const _HomeNavigation()
            : !isPreview
            ? SafeArea(
                top: false,
                child: TextButton(
                  onPressed: vm.isSaving ? null : onSignOut,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppTokens.touchTarget,
                    ),
                  ),
                  child: const Text('Đăng xuất'),
                ),
              )
            : null,
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTokens.contentMaxWidth),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageInset,
          AppTokens.space4,
          AppTokens.pageInset,
          AppTokens.space24,
        ),
        child: child,
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.isPreview});
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.pageInset),
          Row(
            children: [
              const BrandMark(),
              const SizedBox(width: AppTokens.space12),
              Text('VetaLife', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppTokens.space32),
          const _WelcomeHero(),
          const SizedBox(height: AppTokens.space32),
          Text(
            'Ăn xanh hơn,\nkhỏe từng ngày',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.space16),
          Text(
            'Ghi bữa ăn, theo dõi thói quen và đọc gợi ý ngắn theo tinh thần ăn uống nhiều thực vật.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: AppTokens.space32 + AppTokens.space32 + AppTokens.space12,
          ),
          AppButton(
            label: 'Thiết lập mục tiêu',
            onPressed: context.read<OnboardingViewModel>().start,
          ),
          const SizedBox(height: AppTokens.space16),
          Text(
            'Thông tin tham khảo; không thay thế tư vấn y tế.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (isPreview) const _PreviewLabel(),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (textScale > 1.15) {
      // Let the illustration reflow at larger font sizes instead of clipping
      // its accessible text into the fixed geometry of the design snapshot.
      return Container(
        padding: const EdgeInsets.all(AppTokens.pageInset),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppTokens.largeRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ăn đa dạng,\ntừng bước nhỏ',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: AppTokens.onPrimaryContainer),
            ),
            const SizedBox(height: AppTokens.space16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HeroCircle(size: 48, color: AppTokens.success),
                SizedBox(width: AppTokens.space12),
                _HeroCircle(size: 86, color: AppTokens.primary),
                SizedBox(width: AppTokens.space12),
                _HeroCircle(size: 58, color: AppTokens.peach),
              ],
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              'THÓI QUEN TỪ THỰC VẬT',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppTokens.onPrimaryContainer),
            ),
          ],
        ),
      );
    }
    return Container(
      height: AppTokens.heroHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.largeRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // These native circles and their positions are Figma's original illustration.
          final scale = constraints.maxWidth / 320;
          return Stack(
            children: [
              Positioned(
                left: 194 * scale,
                top: 30,
                child: const _HeroCircle(size: 86, color: AppTokens.primary),
              ),
              Positioned(
                left: 226 * scale,
                top: 112,
                child: const _HeroCircle(size: 58, color: AppTokens.peach),
              ),
              Positioned(
                left: 128 * scale,
                top: 96,
                child: const _HeroCircle(size: 48, color: AppTokens.success),
              ),
              Positioned(
                left: AppTokens.pageInset,
                top: AppTokens.pageInset,
                child: SizedBox(
                  width: 180 * scale,
                  child: Text(
                    'Ăn đa dạng,\ntừng bước nhỏ',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: AppTokens.onPrimaryContainer),
                  ),
                ),
              ),
              Positioned(
                left: AppTokens.pageInset,
                bottom: AppTokens.space32 + AppTokens.space16,
                right: AppTokens.pageInset,
                child: Text(
                  'THÓI QUEN TỪ THỰC VẬT',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppTokens.onPrimaryContainer),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _birthDate;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  final _age = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<OnboardingViewModel>();
    _name = TextEditingController(text: vm.displayName);
    _birthDate = TextEditingController(text: vm.birthDateText);
    _weight = TextEditingController(text: vm.weightText);
    _height = TextEditingController(text: vm.heightText);
  }

  @override
  void dispose() {
    _name.dispose();
    _birthDate.dispose();
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<OnboardingViewModel>();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          vm.birthDate ??
          DateTime(vm.today.year - 25, vm.today.month, vm.today.day),
      firstDate: DateTime(1),
      lastDate: vm.today,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      fieldLabelText: 'Ngày sinh',
      fieldHintText: 'dd/MM/yyyy',
      errorFormatText: 'Ngày chưa đúng định dạng',
      errorInvalidText: 'Vui lòng chọn ngày không ở tương lai',
    );
    if (!mounted || selected == null) return;
    final value =
        '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year.toString().padLeft(4, '0')}';
    _birthDate.text = value;
    vm.updateBirthDate(value);
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    context.read<OnboardingViewModel>().continueToGoals();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();
    final theme = Theme.of(context);
    _age.text = vm.age?.toString() ?? '—';
    return _PageContent(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar(title: 'Tạo hồ sơ', onBack: vm.back),
            const SizedBox(height: AppTokens.space16),
            Text(
              'BƯỚC 1 / 2',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            Text('Thông tin của bạn', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTokens.space12),
            Text(
              'Cho chúng mình biết một chút về bạn.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            AppTextField(
              key: const ValueKey('profile_name'),
              label: 'Họ và tên *',
              controller: _name,
              onChanged: vm.updateDisplayName,
              hint: 'Nhập họ và tên',
              helper: 'Có thể chỉnh sửa sau',
              error: vm.errors['displayName'],
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: AppTokens.space16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const ValueKey('profile_birth_date'),
                        label: 'Ngày sinh *',
                        controller: _birthDate,
                        onChanged: vm.updateBirthDate,
                        hint: 'dd/MM/yyyy',
                        error: vm.errors['birthDate'],
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.birthday],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _selectBirthDate,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(
                              AppTokens.touchTarget,
                              AppTokens.touchTarget,
                            ),
                          ),
                          child: const Text('Chọn ngày sinh'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: AppTextField(
                    key: const ValueKey('profile_age'),
                    label: 'Tuổi',
                    controller: _age,
                    onChanged: null,
                    readOnly: true,
                    helper: 'Tự tính từ ngày sinh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    key: const ValueKey('profile_weight'),
                    label: 'Cân nặng *',
                    controller: _weight,
                    onChanged: vm.updateWeight,
                    hint: 'Nhập cân nặng',
                    helper: 'Đơn vị: kg',
                    error: vm.errors['weightKg'],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: AppTextField(
                    key: const ValueKey('profile_height'),
                    label: 'Chiều cao *',
                    controller: _height,
                    onChanged: vm.updateHeight,
                    hint: 'Nhập số đo',
                    helper: 'Đơn vị: cm',
                    error: vm.errors['heightCm'],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              'Thông tin chỉ dùng cho hồ sơ của bạn. Bạn có thể chỉnh sửa sau.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            AppButton(label: 'Tiếp tục', onPressed: _continue),
          ],
        ),
      ),
    );
  }
}

class GoalSetupScreen extends StatelessWidget {
  const GoalSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();
    final theme = Theme.of(context);
    return _PageContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTopBar(
            title: 'Mục tiêu của bạn',
            showBack: true,
            onBack: vm.isSaving ? null : vm.back,
          ),
          const SizedBox(height: AppTokens.space16),
          const LinearProgressIndicator(
            value: 1,
            minHeight: AppTokens.setupProgressHeight,
            borderRadius: BorderRadius.all(
              Radius.circular(AppTokens.pillRadius),
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            'BƯỚC 2 / 2',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            'Bạn muốn bắt đầu từ đâu?',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTokens.space32 + AppTokens.space16),
          for (final goal in HabitGoal.values) ...[
            AppCard(
              key: ValueKey('goal_${goal.name}'),
              title: '${vm.selectedGoal == goal ? '✓ ' : ''}${goal.title}',
              body: vm.selectedGoal == goal
                  ? 'Đã chọn · Một mục tiêu nhỏ cho hôm nay.'
                  : goal.description,
              selected: vm.selectedGoal == goal,
              onTap: vm.isSaving ? null : () => vm.selectGoal(goal),
            ),
            const SizedBox(height: AppTokens.space12),
          ],
          const SizedBox(height: AppTokens.space16),
          if (vm.errorMessage != null) ...[
            AppInlineError(message: vm.errorMessage!),
            const SizedBox(height: AppTokens.space12),
          ],
          AppButton(
            label: vm.errorMessage == null ? 'Lưu mục tiêu' : 'Thử lưu lại',
            onPressed: vm.save,
            isLoading: vm.isSaving,
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            'Bạn có thể thay đổi mục tiêu bất cứ lúc nào.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSignOut,
    required this.isPreview,
  });
  final VoidCallback onSignOut;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();
    final meals = context.watch<MealViewModel?>();
    final learning = context.watch<LearningViewModel?>();
    final mealCount = meals?.todayCount ?? 0;
    final theme = Theme.of(context);
    final profile = vm.profile;
    if (profile == null) {
      return AppErrorState(
        message: 'Hồ sơ chưa sẵn sàng. Vui lòng tải lại.',
        onRetry: vm.init,
      );
    }
    return _PageContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTopBar(
            title: 'VetaLife',
            trailing: PopupMenuButton<String>(
              tooltip: 'Hồ sơ của bạn',
              enabled: !vm.isSaving,
              icon: vm.isSaving
                  ? const SizedBox(
                      width: AppTokens.space24,
                      height: AppTokens.space24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onSelected: (value) {
                if (value == 'profile') vm.editProfile();
                if (value == 'sign_out') onSignOut();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Text('Chỉnh sửa hồ sơ và mục tiêu'),
                ),
                PopupMenuItem(value: 'sign_out', child: Text('Đăng xuất')),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          if (vm.errorMessage != null) ...[
            AppInlineError(message: vm.errorMessage!),
            const SizedBox(height: AppTokens.space12),
          ],
          Text(
            'Chào ${profile.displayName}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            MaterialLocalizations.of(context).formatFullDate(vm.today),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          AppCard(
            title: 'Mục tiêu hôm nay',
            body: profile.goal.title,
            selected: true,
          ),
          const SizedBox(height: AppTokens.space16),
          if (meals?.journalError != null) ...[
            AppInlineError(message: meals!.journalError!),
            const SizedBox(height: AppTokens.space12),
          ],
          Text(
            meals?.isLoadingJournal == true
                ? 'Đang tải nhật ký…'
                : meals?.journalError != null
                ? 'Chưa tải được số bữa hôm nay'
                : mealCount == 0
                ? 'Chưa có bữa ăn nào được ghi lại'
                : '$mealCount bữa ăn đã ghi hôm nay',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: AppTokens.space12),
          LinearProgressIndicator(
            value: mealCount > 0 ? 1 : 0,
            semanticsLabel: mealCount > 0
                ? 'Đã có ghi chép hôm nay'
                : 'Chưa có ghi chép hôm nay',
            minHeight: AppTokens.progressHeight,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppTokens.pillRadius),
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          AppCard(title: 'Gợi ý hôm nay', body: profile.goal.suggestion),
          const SizedBox(height: AppTokens.space24),
          AppButton(label: 'Ghi bữa ăn', onPressed: meals?.startNew),
          const SizedBox(height: AppTokens.space16),
          TextButton(
            onPressed: learning?.showProgress,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, AppTokens.touchTarget),
            ),
            child: const Text('Xem tiến trình tuần  →'),
          ),
          if (isPreview) const _PreviewLabel(),
        ],
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppTokens.space12),
    child: Text(
      'Bản xem thử · Dữ liệu lưu trên thiết bị',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    ),
  );
}

class _HomeNavigation extends StatelessWidget {
  const _HomeNavigation();

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealViewModel?>();
    final learning = context.watch<LearningViewModel?>();
    return MealNavigation(
      selectedIndex: 0,
      onSelected: (index) {
        if (index == 1) meals?.openJournal();
        if (index == 2) learning?.showProgress();
        if (index == 3) learning?.showCatalog();
      },
    );
  }
}
