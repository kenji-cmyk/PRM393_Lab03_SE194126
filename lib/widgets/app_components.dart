import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel = 'Đang lưu…',
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: isLoading ? null : onPressed,
    child: isLoading
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppTokens.space24,
                height: AppTokens.space24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Flexible(child: Text(loadingLabel)),
            ],
          )
        : Text(label, textAlign: TextAlign.center),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hint,
    this.helper,
    this.error,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.readOnly = false,
    this.enabled = true,
    this.suffix,
    this.inputFormatters,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final bool enabled;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTokens.space6),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            readOnly: readOnly,
            canRequestFocus: !readOnly,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            onSubmitted: onSubmitted,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: suffix,
              fillColor: readOnly
                  ? AppTokens.canvas
                  : theme.colorScheme.surface,
              enabledBorder: readOnly
                  ? OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTokens.border),
                      borderRadius: BorderRadius.circular(
                        AppTokens.smallRadius,
                      ),
                    )
                  : null,
              constraints: const BoxConstraints(
                minHeight: AppTokens.controlHeight,
              ),
              // Helpers live below the control so long localized errors can wrap.
              errorText: error,
              errorMaxLines: 4,
            ),
          ),
        ),
        if (helper != null && error == null) ...[
          const SizedBox(height: AppTokens.space6),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.title,
    required this.body,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      selected: onTap == null ? null : selected,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTokens.largeRadius),
          border: selected
              ? Border.all(color: theme.colorScheme.primary)
              : null,
          boxShadow: selected ? null : const [AppTokens.cardShadow],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.largeRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppTokens.cardHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = false,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTokens.appBarHeight),
      child: Row(
        children: [
          if (onBack != null || showBack)
            IconButton(
              tooltip: 'Quay lại',
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppTokens.touchTarget,
                minHeight: AppTokens.touchTarget,
              ),
              icon: Container(
                width: AppTokens.brandActionSize,
                height: AppTokens.brandActionSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTokens.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/back.svg',
                  excludeFromSemantics: true,
                ),
              ),
            )
          else
            const SizedBox(
              width: AppTokens.touchTarget,
              height: AppTokens.touchTarget,
              child: Center(child: BrandMark(size: AppTokens.brandActionSize)),
            ),
          const SizedBox(width: AppTokens.space4),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = AppTokens.brandSize});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppTokens.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        'VL',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTokens.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message = 'Đang tải hồ sơ…'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTokens.space16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTokens.contentMaxWidth),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.pageInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chưa thể tải hồ sơ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space24),
            AppButton(label: 'Thử lại', onPressed: onRetry),
          ],
        ),
      ),
    ),
  );
}

class AppInlineError extends StatelessWidget {
  const AppInlineError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    ),
  );
}

Future<void> showUpcomingFlow(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Đã hiểu'),
      ),
    ],
  ),
);
