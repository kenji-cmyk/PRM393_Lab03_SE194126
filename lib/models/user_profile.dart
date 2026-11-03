import '../utils/calendar_date.dart';
import 'habit_goal.dart';

/// Owner identity belongs to the repository path, never to client profile data.
class UserProfile {
  UserProfile({
    required String displayName,
    required DateTime birthDate,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
  }) : displayName = displayName.trim(),
       birthDate = calendarDate(birthDate) {
    if (this.displayName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName', 'Name is required');
    }
    if (birthDate.year < 1 || birthDate.year > 9999) {
      throw ArgumentError.value(
        birthDate,
        'birthDate',
        'Invalid calendar year',
      );
    }
    if (!weightKg.isFinite || weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Must be finite and positive',
      );
    }
    if (!heightCm.isFinite || heightCm <= 0) {
      throw ArgumentError.value(
        heightCm,
        'heightCm',
        'Must be finite and positive',
      );
    }
  }

  final String displayName;
  final DateTime birthDate;
  final double weightKg;
  final double heightCm;
  final HabitGoal goal;

  int ageAt(DateTime today) => ageOn(birthDate, today);

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'birthDate': formatCalendarDate(birthDate, iso: true),
    'weightKg': weightKg,
    'heightCm': heightCm,
    'goal': goal.name,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final name = json['displayName'];
    final dateText = json['birthDate'];
    final weight = json['weightKg'];
    final height = json['heightCm'];
    final goalName = json['goal'];
    if (name is! String ||
        name.trim().isEmpty ||
        dateText is! String ||
        weight is! num ||
        !weight.isFinite ||
        weight <= 0 ||
        height is! num ||
        !height.isFinite ||
        height <= 0 ||
        goalName is! String) {
      throw const FormatException('Invalid profile data');
    }
    final date = parseCalendarDate(dateText, iso: true);
    final goal = HabitGoal.values.where((value) => value.name == goalName);
    if (date == null || goal.isEmpty) {
      throw const FormatException('Invalid profile date or goal');
    }
    return UserProfile(
      displayName: name,
      birthDate: date,
      weightKg: weight.toDouble(),
      heightCm: height.toDouble(),
      goal: goal.single,
    );
  }
}
