import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'onboarding_repository.dart';

/// Explicit preview storage. Never used by the Firebase build.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const storageKey = 'vetalife.preview.profile.v1';
  static const _legacyStorageKey = 'nep_lanh.preview.profile.v1';

  @override
  Future<UserProfile?> load() async {
    final currentValue = await _preferences.getString(storageKey);
    final value =
        currentValue ?? await _preferences.getString(_legacyStorageKey);
    if (value == null) return null;
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid stored profile');
    }
    final profile = UserProfile.fromJson(json);
    if (currentValue == null) {
      // Validate and copy before removing the old brand's stored profile.
      await _preferences.setString(storageKey, value);
      await _preferences.remove(_legacyStorageKey);
    }
    return profile;
  }

  @override
  Future<void> save(UserProfile profile) =>
      _preferences.setString(storageKey, jsonEncode(profile.toJson()));

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
    await _preferences.remove(_legacyStorageKey);
  }
}
