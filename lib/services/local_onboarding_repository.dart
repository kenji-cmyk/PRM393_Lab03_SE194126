import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'onboarding_repository.dart';

/// Explicit preview storage. Never used by the Firebase build.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const storageKey = 'nep_lanh.preview.profile.v1';

  @override
  Future<UserProfile?> load() async {
    final value = await _preferences.getString(storageKey);
    if (value == null) return null;
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid stored profile');
    }
    return UserProfile.fromJson(json);
  }

  @override
  Future<void> save(UserProfile profile) =>
      _preferences.setString(storageKey, jsonEncode(profile.toJson()));

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}
