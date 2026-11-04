import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../services/meal_photo_picker.dart';
import '../theme/app_theme.dart';
import '../viewmodels/meal_view_model.dart';
import '../widgets/app_components.dart';
import '../widgets/meal_navigation.dart';

/// Figma flow 2, with an explicit review step between recognition and analysis.
///
/// Routing stays inside the authenticated session rather than pushing routes
/// which could outlive sign-out or expose the previous account's meal draft.
class MealFlowScreen extends StatelessWidget {
  const MealFlowScreen({
    super.key,
    required this.onHome,
    this.onProgress,
    this.onLearn,
  });

  final VoidCallback onHome;
  final VoidCallback? onProgress;
  final VoidCallback? onLearn;

  void _back(MealViewModel vm) {
    if (vm.isSaving) return;
    if (vm.stage == MealStage.entry || vm.stage == MealStage.journal) {
      onHome();
    } else if (vm.viewingSaved) {
      vm.openJournal();
    } else {
      vm.editDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final journal = vm.stage == MealStage.journal;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(vm);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: !journal,
          child: _MealPage(
            key: ValueKey(vm.stage),
            child: switch (vm.stage) {
              MealStage.entry => _MealEntry(onBack: () => _back(vm)),
              MealStage.confirm => _MealConfirmation(onBack: vm.editDraft),
              MealStage.recognizing => _MealProcessing(
                recognizing: true,
                onBack: vm.editDraft,
              ),
              MealStage.analyzing => _MealProcessing(
                recognizing: false,
                onBack: vm.editDraft,
              ),
              MealStage.result => _MealResult(onBack: () => _back(vm)),
              MealStage.error => _MealFailure(onBack: vm.editDraft),
              MealStage.journal => const _MealJournal(),
              MealStage.home => const SizedBox.shrink(),
            },
          ),
        ),
        bottomNavigationBar: journal
            ? MealNavigation(
                selectedIndex: 1,
                onSelected: (index) {
                  if (index == 0) onHome();
                  if (index == 2) onProgress?.call();
                  if (index == 3) onLearn?.call();
                },
              )
            : null,
      ),
    );
  }
}

class _MealPage extends StatelessWidget {
  const _MealPage({super.key, required this.child});

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

class _MealEntry extends StatelessWidget {
  const _MealEntry({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final draft = vm.draft;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(title: 'Ghi bữa ăn', onBack: onBack),
        const SizedBox(height: AppTokens.space16),
        Text('Ghi nhanh bữa ăn', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTokens.space16),
        _MealTextInput(
          key: const ValueKey('meal-name'),
          label: 'Tên món',
          value: draft.name,
          onChanged: vm.updateName,
          hint: 'Nhập tên món bạn vừa ăn',
          helper: 'Mô tả bằng tên quen thuộc',
          error: vm.errors['name'],
        ),
        const SizedBox(height: AppTokens.space12),
        _MealTimeInput(),
        const SizedBox(height: AppTokens.space12),
        const AppCard(
          title: 'Gợi ý ghi chép',
          body: 'Thêm món chính và rau ăn kèm; không cần đếm calo.',
        ),
        const SizedBox(height: AppTokens.space24),
        const _MealPhotoPanel(),
        const SizedBox(height: AppTokens.space16),
        _MealTextInput(
          key: const ValueKey('meal-notes'),
          label: 'Ghi chú của bạn (không bắt buộc)',
          value: draft.notes,
          onChanged: vm.updateNotes,
          hint: 'Ví dụ: ít nước chấm, thêm rau',
          error: vm.errors['notes'],
        ),
        const SizedBox(height: AppTokens.space24),
        if (vm.errorMessage != null) ...[
          AppInlineError(message: vm.errorMessage!),
          const SizedBox(height: AppTokens.space12),
        ],
        AppButton(label: 'Tiếp tục xác nhận', onPressed: vm.reviewIngredients),
        const SizedBox(height: AppTokens.space16),
        const _ModeLabel(),
        const SizedBox(height: AppTokens.space12),
        const _EducationalNote(),
      ],
    );
  }
}

class _MealTimeInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bữa ăn', style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTokens.space6),
        DropdownButtonFormField<MealType>(
          key: ValueKey(vm.draft.mealType),
          initialValue: vm.draft.mealType,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: [
            for (final type in MealType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (value) {
            if (value != null) vm.updateMealType(value);
          },
        ),
        const SizedBox(height: AppTokens.space6),
        OutlinedButton.icon(
          onPressed: () => _selectMealTime(context, vm),
          icon: const Icon(Icons.schedule_outlined),
          label: Text(
            '${_dateLabel(context, vm.draft.eatenAt)} · '
            '${_timeLabel(context, vm.draft.eatenAt)}',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, AppTokens.touchTarget),
          ),
        ),
        const SizedBox(height: AppTokens.space6),
        Text(
          'Bạn có thể chỉnh sửa sau',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (vm.errors['eatenAt'] != null)
          AppInlineError(message: vm.errors['eatenAt']!),
      ],
    );
  }

  Future<void> _selectMealTime(BuildContext context, MealViewModel vm) async {
    final current = vm.draft.eatenAt;
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current.isAfter(today) ? today : current,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !context.mounted) return;
    vm.updateEatenAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _MealPhotoPanel extends StatelessWidget {
  const _MealPhotoPanel();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final photo = vm.photo;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.largeRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thêm ảnh bữa ăn', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTokens.space8),
          Text(
            'Chụp món ăn hoặc chọn ảnh có sẵn. Bạn sẽ kiểm tra thành phần '
            'trước khi phân tích.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space12),
          if (photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.mediumRadius),
              child: Image.memory(
                photo.bytes,
                height: 184,
                fit: BoxFit.cover,
                semanticLabel: 'Ảnh bữa ăn bạn đã chọn',
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(AppTokens.space16),
                  child: Text('Không hiển thị được ảnh. Hãy chọn ảnh khác.'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: vm.isPickingPhoto ? null : vm.removePhoto,
                icon: const Icon(Icons.close),
                label: const Text('Bỏ ảnh'),
              ),
            ),
          ],
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: [
              OutlinedButton.icon(
                onPressed: vm.isPickingPhoto
                    ? null
                    : () => vm.pickPhoto(MealPhotoSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Chụp ảnh'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppTokens.touchTarget),
                ),
              ),
              OutlinedButton.icon(
                onPressed: vm.isPickingPhoto
                    ? null
                    : () => vm.pickPhoto(MealPhotoSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppTokens.touchTarget),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          if (vm.isPickingPhoto) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppTokens.space12),
          ],
          if (!vm.canRecognize)
            Text(
              'Nhận diện ảnh bằng Gemini có trong chế độ cloud sau khi đăng '
              'nhập. Bản xem thử cho phép bạn tự nhập thành phần và đối chiếu sách.',
              style: theme.textTheme.bodySmall,
            )
          else if (photo != null) ...[
            const _CloudConsent(),
            const SizedBox(height: AppTokens.space12),
            AppButton(
              label: 'Nhận diện món từ ảnh',
              onPressed: vm.consent && !vm.isPickingPhoto
                  ? vm.recognizePhoto
                  : null,
            ),
          ],
          const SizedBox(height: AppTokens.space8),
          Text(
            'Ảnh chỉ dùng để nhận diện, không lưu vào nhật ký. OCR đọc chữ '
            'trên ảnh; thành phần món ăn là gợi ý cần bạn xác nhận.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (vm.errors['photo'] != null) ...[
            const SizedBox(height: AppTokens.space8),
            AppInlineError(message: vm.errors['photo']!),
          ],
        ],
      ),
    );
  }
}

class _MealConfirmation extends StatelessWidget {
  const _MealConfirmation({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final theme = Theme.of(context);
    final recognition = vm.recognition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(title: 'Xác nhận bữa ăn', onBack: onBack),
        const SizedBox(height: AppTokens.space24),
        Text(
          'Kiểm tra món và thành phần',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space12),
        Text(
          recognition == null
              ? 'Thêm những thành phần bạn biết. Có thể để trống lượng ăn '
                    'hoặc cách chế biến nếu chưa rõ.'
              : 'Đây là gợi ý nhận diện từ ảnh. Sửa hoặc bỏ thành phần chưa '
                    'đúng và thêm những gì ảnh không thể hiện.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTokens.space24),
        _MealTextInput(
          key: const ValueKey('confirmed-meal-name'),
          label: 'Tên món',
          value: vm.draft.name,
          onChanged: vm.updateName,
          error: vm.errors['name'],
        ),
        const SizedBox(height: AppTokens.space16),
        if (recognition != null) ...[
          for (final warning in recognition.warnings) ...[
            _InformationNote(message: warning),
            const SizedBox(height: AppTokens.space8),
          ],
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Chữ đọc từ ảnh (OCR)'),
            childrenPadding: const EdgeInsets.only(bottom: AppTokens.space16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  recognition.ocrText.trim().isEmpty
                      ? 'Không đọc được chữ rõ ràng trong ảnh.'
                      : recognition.ocrText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
        ],
        for (final (index, ingredient) in vm.draft.ingredients.indexed) ...[
          _IngredientEditor(
            key: ValueKey('ingredient-$index'),
            index: index,
            ingredient: ingredient,
          ),
          const SizedBox(height: AppTokens.space12),
        ],
        if (vm.draft.ingredients.isEmpty)
          const _InformationNote(
            message:
                'Chưa có thành phần nào. Thêm ít nhất một món hoặc nguyên '
                'liệu bạn đã ăn để đối chiếu nội dung sách.',
          ),
        if (vm.errors['ingredients'] != null) ...[
          const SizedBox(height: AppTokens.space8),
          AppInlineError(message: vm.errors['ingredients']!),
        ],
        TextButton.icon(
          key: const ValueKey('add-meal-ingredient'),
          onPressed: () => vm.addIngredient(const MealIngredient(name: '')),
          icon: const Icon(Icons.add),
          label: const Text('Thêm thành phần'),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, AppTokens.touchTarget),
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        const _InformationNote(
          message:
              'Ảnh không xác định chắc chắn lượng ăn, dầu, muối, đường '
              'hoặc thành phần ẩn. Ghi thêm những thông tin bạn biết.',
        ),
        const SizedBox(height: AppTokens.space16),
        CheckboxListTile(
          key: const ValueKey('meal-confirmed'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Tôi đã kiểm tra món và các thành phần ở trên'),
          value: vm.confirmed,
          onChanged: (value) => vm.setConfirmed(value ?? false),
        ),
        if (vm.errors['confirmed'] != null)
          AppInlineError(message: vm.errors['confirmed']!),
        if (vm.isCloud) ...[
          const SizedBox(height: AppTokens.space8),
          const _CloudConsent(),
        ],
        const SizedBox(height: AppTokens.space24),
        AppButton(
          label: vm.isCloud ? 'Phân tích bữa ăn' : 'Đối chiếu với sách',
          onPressed: vm.confirmed && (!vm.isCloud || vm.consent)
              ? vm.analyze
              : null,
        ),
        const SizedBox(height: AppTokens.space16),
        const _ModeLabel(),
        const SizedBox(height: AppTokens.space12),
        const _EducationalNote(),
      ],
    );
  }
}

class _IngredientEditor extends StatelessWidget {
  const _IngredientEditor({
    super.key,
    required this.index,
    required this.ingredient,
  });

  final int index;
  final MealIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MealViewModel>();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.largeRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thành phần ${index + 1}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Bỏ thành phần ${index + 1}',
                onPressed: () => vm.removeIngredient(index),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          _MealTextInput(
            key: ValueKey('ingredient-name-$index'),
            label: 'Tên thành phần ${index + 1}',
            value: ingredient.name,
            hint: 'Ví dụ: đậu hũ, rau cải',
            onChanged: (value) => vm.updateIngredient(
              index,
              MealIngredient(
                name: value,
                amount: ingredient.amount,
                preparation: ingredient.preparation,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          _MealTextInput(
            key: ValueKey('ingredient-amount-$index'),
            label: 'Lượng ăn (nếu biết)',
            value: ingredient.amount,
            hint: 'Ví dụ: một bát nhỏ',
            onChanged: (value) => vm.updateIngredient(
              index,
              MealIngredient(
                name: ingredient.name,
                amount: value,
                preparation: ingredient.preparation,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          _MealTextInput(
            key: ValueKey('ingredient-preparation-$index'),
            label: 'Cách chế biến (nếu biết)',
            value: ingredient.preparation,
            hint: 'Ví dụ: luộc, áp chảo',
            onChanged: (value) => vm.updateIngredient(
              index,
              MealIngredient(
                name: ingredient.name,
                amount: ingredient.amount,
                preparation: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudConsent extends StatelessWidget {
  const _CloudConsent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        key: const ValueKey('meal-cloud-consent'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: vm.consent,
        onChanged: (value) => vm.setConsent(value ?? false),
        title: const Text('Cho phép Gemini xử lý dữ liệu bữa ăn'),
        subtitle: const Text(
          'Ảnh được gửi khi nhận diện. Khi phân tích, bữa ăn cùng tuổi, cân '
          'nặng, chiều cao và mục tiêu được gửi; không gửi tên hoặc ngày sinh.',
        ),
      ),
    );
  }
}

class _MealProcessing extends StatelessWidget {
  const _MealProcessing({required this.recognizing, required this.onBack});

  final bool recognizing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: recognizing ? 'Đang nhận diện' : 'Đang phân tích',
          onBack: onBack,
        ),
        const SizedBox(height: AppTokens.space32),
        Text(
          recognizing ? 'Đang nhận diện món ăn' : 'Đang tổng hợp thông tin',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space24),
        Text(
          recognizing
              ? 'Đọc chữ và gợi ý thành phần có thể thấy trong ảnh.'
              : 'Giữ nguyên bữa ăn trong khi chuẩn bị gợi ý.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.space32),
        Semantics(
          liveRegion: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 136),
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.largeRadius),
            ),
            child: Column(
              children: [
                const _LoadingMealIcon(),
                const SizedBox(height: AppTokens.space8),
                Text(
                  recognizing ? 'Đang đọc ảnh' : 'Đang tổng hợp',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  vm.isCloud
                      ? 'Thông tin sẽ sẵn sàng trong chốc lát.'
                      : 'Đối chiếu nội dung sách trên thiết bị.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space32),
        Text(
          'Bạn có thể quay lại chỉnh sửa bất cứ lúc nào.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppTokens.space32),
        AppButton(label: 'Quay lại chỉnh sửa', onPressed: onBack),
      ],
    );
  }
}

class _LoadingMealIcon extends StatefulWidget {
  const _LoadingMealIcon();

  @override
  State<_LoadingMealIcon> createState() => _LoadingMealIconState();
}

class _LoadingMealIconState extends State<_LoadingMealIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _controller,
    child: SvgPicture.asset(
      'assets/icons/meal-loading.svg',
      excludeFromSemantics: true,
    ),
  );
}

class _MealResult extends StatelessWidget {
  const _MealResult({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final analysis = vm.analysis;
    if (analysis == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: 'Gợi ý bữa ăn',
          onBack: vm.isSaving ? null : onBack,
          showBack: true,
        ),
        const SizedBox(height: AppTokens.space16),
        Text(
          'GỢI Ý THAM KHẢO',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        Text(analysis.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppTokens.space16),
        Text(
          vm.draft.ingredients.map((ingredient) => ingredient.name).join(' · '),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        Text(analysis.summary, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppTokens.space24),
        if (analysis.highlights.isNotEmpty) ...[
          AppCard(
            title: 'Điểm nổi bật',
            body: _bullets(analysis.highlights),
            selected: true,
          ),
          const SizedBox(height: AppTokens.space12),
        ],
        if (analysis.improvements.isNotEmpty) ...[
          AppCard(
            title: 'Gợi ý tiếp theo',
            body: _bullets(analysis.improvements),
          ),
          const SizedBox(height: AppTokens.space12),
        ],
        const SizedBox(height: AppTokens.space24),
        if (vm.errorMessage != null) ...[
          AppInlineError(message: vm.errorMessage!),
          const SizedBox(height: AppTokens.space12),
        ],
        if (vm.viewingSaved)
          AppButton(label: 'Về nhật ký', onPressed: vm.openJournal)
        else
          AppButton(
            label: 'Lưu vào nhật ký',
            onPressed: vm.save,
            isLoading: vm.isSaving,
          ),
        const SizedBox(height: AppTokens.space12),
        TextButton(
          onPressed: vm.isSaving ? null : vm.editDraft,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, AppTokens.touchTarget),
          ),
          child: const Text('Chỉnh sửa thông tin'),
        ),
        if (analysis.profileNote.isNotEmpty) ...[
          AppCard(title: 'Theo hồ sơ của bạn', body: analysis.profileNote),
          const SizedBox(height: AppTokens.space12),
        ],
        if (analysis.healthConnections.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space12),
          Text(
            'Liên hệ kiến thức trong sách',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppTokens.space12),
          for (final connection in analysis.healthConnections) ...[
            AppCard(
              title: connection.topic,
              body:
                  '${connection.explanation}\n\n'
                  '${_referenceLabels(connection.referenceIds, analysis.references)}',
            ),
            const SizedBox(height: AppTokens.space12),
          ],
        ],
        if (analysis.references.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: false,
            title: Text('Nguồn sách · ${analysis.references.length} mục'),
            children: [
              for (final reference in analysis.references)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(reference.title, style: theme.textTheme.labelLarge),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        'Trang sách ${reference.printedPage} · '
                        'Trang PDF ${reference.pdfPage}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space8),
                      Text(reference.summary, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppTokens.space16),
                child: Text(
                  'Ăn gì không chết — Michael Greger và Gene Stone. '
                  'Nội dung trên được diễn giải ngắn theo trang nguồn.',
                ),
              ),
            ],
          ),
        if (analysis.limitations.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space12),
          _InformationNote(message: _bullets(analysis.limitations)),
        ],
        const SizedBox(height: AppTokens.space16),
        Text(
          analysis.mode == 'gemini'
              ? 'Phân tích bằng Gemini · dựa trên thành phần bạn xác nhận'
              : 'Đối chiếu sách trên thiết bị · không phải phân tích AI',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.space12),
        const _EducationalNote(),
      ],
    );
  }
}

class _MealFailure extends StatelessWidget {
  const _MealFailure({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(title: 'Kết nối', onBack: onBack),
        const SizedBox(height: AppTokens.space32),
        Text('Chưa thể tải gợi ý', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppTokens.space24),
        Text(
          'Quay lại biểu mẫu để kiểm tra thông tin bữa ăn.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppTokens.mediumRadius),
          ),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chưa hoàn tất xử lý',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  vm.errorMessage ?? 'Vui lòng kiểm tra kết nối và thử lại.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        AppButton(label: 'Thử lại', onPressed: vm.retry),
        const SizedBox(height: AppTokens.space12),
        TextButton(
          onPressed: onBack,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, AppTokens.touchTarget),
          ),
          child: const Text('Quay lại món ăn'),
        ),
        const SizedBox(height: AppTokens.space16),
        Text(
          'Nội dung bữa ăn vẫn được giữ lại để bạn sửa hoặc thử lại.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MealJournal extends StatelessWidget {
  const _MealJournal();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final theme = Theme.of(context);
    final records = vm.recordsForDate;
    final today = DateUtils.isSameDay(vm.journalDate, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppTopBar(title: 'Nhật ký bữa ăn'),
        const SizedBox(height: AppTokens.space16),
        Text(
          today ? 'Hôm nay' : 'Nhật ký của bạn',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppTokens.space8),
        Row(
          children: [
            IconButton(
              tooltip: 'Ngày trước',
              onPressed: () => vm.selectJournalDate(
                DateTime(
                  vm.journalDate.year,
                  vm.journalDate.month,
                  vm.journalDate.day - 1,
                ),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _selectJournalDate(context, vm),
                child: Text(
                  _dateLabel(context, vm.journalDate),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ngày sau',
              onPressed: today
                  ? null
                  : () => vm.selectJournalDate(
                      DateTime(
                        vm.journalDate.year,
                        vm.journalDate.month,
                        vm.journalDate.day + 1,
                      ),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        if (vm.isLoadingJournal)
          const AppLoadingState(message: 'Đang tải nhật ký…')
        else if (vm.journalError != null) ...[
          AppInlineError(message: vm.journalError!),
          const SizedBox(height: AppTokens.space16),
          AppButton(label: 'Tải lại nhật ký', onPressed: vm.openJournal),
        ] else if (records.isEmpty) ...[
          Text('Ngày chưa ghi bữa', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTokens.space32),
          Container(
            constraints: const BoxConstraints(minHeight: 168),
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.largeRadius),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/meal-empty.svg',
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Chưa có bữa ăn nào',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Ghi bữa đầu tiên để quan sát thói quen.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space32),
          AppButton(label: 'Ghi bữa ăn', onPressed: vm.startNew),
        ] else ...[
          for (final record in records) ...[
            AppCard(
              title:
                  '${record.draft.mealType.label} · '
                  '${_timeLabel(context, record.draft.eatenAt)}',
              body:
                  '${record.draft.name}\n'
                  '${record.draft.ingredients.map((item) => item.name).join(' · ')}',
              onTap: () => vm.showRecord(record),
            ),
            const SizedBox(height: AppTokens.space12),
            if (record.draft.notes.trim().isNotEmpty) ...[
              AppCard(title: 'Ghi chú của bạn', body: record.draft.notes),
              const SizedBox(height: AppTokens.space12),
            ],
          ],
          const SizedBox(height: AppTokens.space12),
          Text(
            '${records.length} bữa ăn đã ghi ${today ? 'hôm nay' : 'trong ngày'}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTokens.space32),
          AppButton(label: 'Ghi thêm bữa ăn', onPressed: vm.startNew),
        ],
        const SizedBox(height: AppTokens.space16),
        const _ModeLabel(),
      ],
    );
  }

  Future<void> _selectJournalDate(
    BuildContext context,
    MealViewModel vm,
  ) async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: vm.journalDate.isAfter(today) ? today : vm.journalDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (date != null && context.mounted) vm.selectJournalDate(date);
  }
}

/// Owns text controllers without resetting cursor/focus on each VM update.
class _MealTextInput extends StatefulWidget {
  const _MealTextInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.helper,
    this.error,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? helper;
  final String? error;

  @override
  State<_MealTextInput> createState() => _MealTextInputState();
}

class _MealTextInputState extends State<_MealTextInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _MealTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: widget.label,
    controller: _controller,
    onChanged: widget.onChanged,
    hint: widget.hint,
    helper: widget.helper,
    error: widget.error,
    textInputAction: TextInputAction.next,
  );
}

class _InformationNote extends StatelessWidget {
  const _InformationNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTokens.space12),
    decoration: BoxDecoration(
      color: AppTokens.primaryContainer,
      borderRadius: BorderRadius.circular(AppTokens.mediumRadius),
    ),
    child: Text(message, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    return Text(
      vm.isCloud
          ? 'Gemini · Hồ sơ và nhật ký theo tài khoản của bạn'
          : 'Bản xem thử · Đối chiếu sách và lưu nhật ký trên thiết bị',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    );
  }
}

class _EducationalNote extends StatelessWidget {
  const _EducationalNote();

  @override
  Widget build(BuildContext context) => Text(
    'Nội dung tham khảo theo chủ đề dinh dưỡng; không thay thế tư vấn '
    'chuyên môn. Một bữa ăn không đủ để kết luận tác dụng phòng bệnh.',
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

String _timeLabel(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(date.toLocal()),
      alwaysUse24HourFormat: true,
    );

String _dateLabel(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatFullDate(date.toLocal());

String _bullets(List<String> values) =>
    values.map((item) => '• $item').join('\n');

String _referenceLabels(List<String> ids, List<BookReference> references) {
  final matches = references.where((reference) => ids.contains(reference.id));
  return matches
      .map((reference) => '${reference.title} · trang ${reference.printedPage}')
      .join('\n');
}
