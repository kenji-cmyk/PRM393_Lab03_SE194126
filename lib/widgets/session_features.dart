import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/cloud_settings_screen.dart';
import '../screens/flow_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/report_screen.dart';
import '../services/app_settings.dart';
import '../services/app_dependencies.dart';
import '../services/app_telemetry.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../viewmodels/learning_view_model.dart';
import '../viewmodels/meal_view_model.dart';
import '../viewmodels/notification_view_model.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../viewmodels/report_view_model.dart';
import 'app_components.dart';

/// Routes and generated personal data belong to this session's provider tree.
/// Removing the UID-keyed tree also removes every open feature screen.
class SessionFeatures extends StatefulWidget {
  const SessionFeatures({
    super.key,
    required this.isPreview,
    required this.onSignOut,
    this.uid,
  });
  final bool isPreview;
  final String? uid;
  final Future<void> Function() onSignOut;

  @override
  State<SessionFeatures> createState() => _SessionFeaturesState();
}

class _SessionFeaturesState extends State<SessionFeatures> {
  final _navigator = GlobalKey<NavigatorState>();
  FirebaseNotificationService? _notificationService;
  NotificationViewModel? _notifications;
  ReportViewModel? _report;
  bool _signingOut = false;
  bool _scheduled = false;
  String? _lastForegroundId;

  AppTelemetry get _telemetry =>
      context.read<AppTelemetry?>() ?? const NoopAppTelemetry();

  @override
  void initState() {
    super.initState();
    if (!widget.isPreview) {
      final service = FirebaseNotificationService(uid: widget.uid!);
      _notificationService = service;
      _notifications = NotificationViewModel(service)
        ..addListener(_notificationChanged);
      unawaited(_notifications!.initialize());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report ??= ReportViewModel(
      service: widget.isPreview
          ? PdfReportService()
          : AppDependencies.reportsFor(widget.uid!),
      isPreview: widget.isPreview,
      onEvent: (name) => unawaited(_telemetry.event(name)),
      onError: (_) => unawaited(_telemetry.handledError('report_upload')),
      snapshot: () async {
        final onboarding = context.read<OnboardingViewModel>();
        final meals = context.read<MealViewModel>();
        final learning = context.read<LearningViewModel>();
        final profile = onboarding.profile;
        if (profile == null ||
            onboarding.isSaving ||
            meals.isSaving ||
            meals.isLoadingJournal ||
            meals.journalError != null ||
            learning.isLoading ||
            learning.isSaving ||
            !learning.progressReady) {
          throw StateError('Saved report data not ready');
        }
        if (!context.read<AppSettings>().reportExportEnabled) {
          throw StateError('Report export temporarily disabled');
        }
        return ReportData(
          profile: profile,
          meals: meals.records,
          progress: learning.readProgress,
          catalog: learning.catalog,
        );
      },
    )..addListener(_reportChanged);
  }

  void _reportChanged() {
    if (_notifications?.pendingDestination != null) _notificationChanged();
  }

  void _notificationChanged() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _signingOut) return;
      final latest = _notifications?.latest;
      final navContext = _navigator.currentContext;
      if (latest != null &&
          latest.id != _lastForegroundId &&
          navContext != null) {
        _lastForegroundId = latest.id;
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(
              latest.title.isEmpty ? 'Bạn có thông báo mới.' : latest.title,
            ),
            action: SnackBarAction(label: 'Xem', onPressed: _showNotifications),
          ),
        );
      }
      final onboarding = context.read<OnboardingViewModel>();
      final meals = context.read<MealViewModel>();
      final learning = context.read<LearningViewModel>();
      if (onboarding.stage != OnboardingStage.home ||
          onboarding.isSaving ||
          meals.isSaving ||
          learning.isSaving ||
          _report!.isBusy ||
          _report!.isOpening) {
        return;
      }
      final destination = _notifications?.takeDestination();
      if (destination != null) _openDestination(destination);
    });
    // Listener can run without an existing frame (e.g. an FCM callback).
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _push(Widget screen) {
    if (_signingOut || _report!.isBusy || _report!.isOpening) return;
    _navigator.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _showNotifications() {
    if (_notifications == null) return;
    unawaited(_notifications!.refresh());
    _push(NotificationScreen(onOpen: _openDestination));
  }

  void _openDestination(NotificationDestination destination) {
    final meals = context.read<MealViewModel>();
    final learning = context.read<LearningViewModel>();
    if (_signingOut ||
        meals.isSaving ||
        learning.isSaving ||
        _report!.isBusy ||
        _report!.isOpening) {
      return;
    }
    _navigator.currentState?.popUntil((route) => route.isFirst);
    meals.showHome();
    learning.showHome();
    switch (destination) {
      case NotificationDestination.home:
        break;
      case NotificationDestination.journal:
        meals.openJournal();
      case NotificationDestination.progress:
        learning.showProgress();
      case NotificationDestination.learn:
        if (context.read<AppSettings>().learningEnabled) {
          learning.showCatalog();
        }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut || _report!.isBusy || _report!.isOpening) return;
    if (widget.isPreview) {
      await widget.onSignOut();
      return;
    }
    setState(() => _signingOut = true);
    try {
      try {
        // Finish token invalidation before another account may register a token.
        // A timeout here would leave deletion running against a new session.
        await _notificationService?.disableForSignOut();
      } catch (_) {
        unawaited(_telemetry.handledError('notification'));
      }
      if (mounted) await widget.onSignOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconsider a pending notification after onboarding or a save completes.
    context.watch<OnboardingViewModel>();
    context.watch<MealViewModel>();
    context.watch<LearningViewModel>();
    if (_notifications?.pendingDestination != null) _notificationChanged();
    final settings = context.watch<AppSettings>();
    Widget child = Navigator(
      key: _navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => FlowScreen(
          isPreview: widget.isPreview,
          onSignOut: _signOut,
          onNotifications: _notifications == null ? null : _showNotifications,
          onReport: () {
            if (settings.reportExportEnabled) {
              _push(ReportScreen(viewModel: _report!));
            }
          },
          onSettings: () => _push(
            CloudSettingsScreen(
              settings: settings,
              telemetry: _telemetry,
              isPreview: widget.isPreview,
            ),
          ),
        ),
      ),
    );
    if (_notifications != null) {
      child = ChangeNotifierProvider.value(
        value: _notifications!,
        child: child,
      );
    }
    child = NavigatorPopHandler<void>(
      onPopWithResult: (_) => _navigator.currentState?.maybePop(),
      child: child,
    );
    return PopScope(
      canPop: !_signingOut,
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _signingOut,
            child: ExcludeFocus(excluding: _signingOut, child: child),
          ),
          if (_signingOut)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: AppLoadingState(message: 'Đang đăng xuất…'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notifications?.removeListener(_notificationChanged);
    _notifications?.dispose();
    _report?.removeListener(_reportChanged);
    _report?.dispose();
    super.dispose();
  }
}
