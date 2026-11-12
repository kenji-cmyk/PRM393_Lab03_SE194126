import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'admin/admin_app.dart';
import 'admin/admin_services.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Trang quản trị chỉ chạy trên trình duyệt web.'),
          ),
        ),
      ),
    );
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '127.0.0.1',
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .useFunctionsEmulator(host, 5001);
    } else {
      const adminHost = String.fromEnvironment('ADMIN_FUNCTIONS_HOST');
      const adminPort = int.fromEnvironment(
        'ADMIN_FUNCTIONS_PORT',
        defaultValue: 5178,
      );
      if (adminHost.isNotEmpty) {
        // This opt-in uses real Firebase Auth with a trusted local admin API.
        // Never send admin ID tokens to an arbitrary host supplied at build time.
        if (!const {'127.0.0.1', 'localhost', '::1'}.contains(adminHost) ||
            adminPort < 1 ||
            adminPort > 65535) {
          throw StateError(
            'Admin API host must be loopback with a valid port.',
          );
        }
        FirebaseFunctions.instanceFor(region: 'asia-southeast1')
            .useFunctionsEmulator(adminHost, adminPort);
      }
    }
    runApp(
      AdminApp(
        sessionService: FirebaseAdminSessionService(),
        userService: FirebaseAdminUserService(),
      ),
    );
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa kết nối được Firebase. Kiểm tra cấu hình và tải lại trang.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
