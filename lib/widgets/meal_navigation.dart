import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Shared home/journal navigation, using the original Figma icon assets.
class MealNavigation extends StatelessWidget {
  const MealNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      ('Trang chủ', 'home'),
      ('Nhật ký', 'journal'),
      ('Tiến trình', 'progress'),
      ('Học', 'learn'),
    ];
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: const Border(top: BorderSide(color: AppTokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTokens.navHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space16,
              vertical: AppTokens.space8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, destination) in destinations.indexed)
                  Expanded(
                    child: Semantics(
                      selected: index == selectedIndex,
                      button: true,
                      child: Material(
                        color: index == selectedIndex
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppTokens.mediumRadius,
                        ),
                        child: InkWell(
                          onTap: () => onSelected(index),
                          borderRadius: BorderRadius.circular(
                            AppTokens.mediumRadius,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: AppTokens.navItemHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTokens.space4,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/${destination.$2}.svg',
                                    excludeFromSemantics: true,
                                  ),
                                  const SizedBox(height: AppTokens.space4),
                                  Text(
                                    destination.$1,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: index == selectedIndex
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
