import '../models/user_profile.dart';

/// Implementations bind all reads/writes to the current signed-in account.
abstract class OnboardingRepository {
  Future<UserProfile?> load();
  Future<void> save(UserProfile profile);
  Future<void> clear();
}
