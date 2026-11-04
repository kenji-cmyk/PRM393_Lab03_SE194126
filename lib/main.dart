import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const mode = String.fromEnvironment('APP_MODE', defaultValue: 'preview');
  runApp(const VetaLifeApp(isPreview: mode == 'preview'));
}
