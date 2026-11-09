import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const mode = String.fromEnvironment('APP_MODE', defaultValue: 'preview');
  if (mode == 'cloud') registerNotificationBackgroundHandler();
  runApp(const VetaLifeApp(isPreview: mode == 'preview'));
}
