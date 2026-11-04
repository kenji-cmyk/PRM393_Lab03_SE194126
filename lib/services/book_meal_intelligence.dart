import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/meal.dart';
import '../models/habit_goal.dart';
import '../models/user_profile.dart';
import '../utils/food_matching.dart';
import 'meal_intelligence.dart';

class BookMealIntelligence implements MealIntelligence {
  BookMealIntelligence({Future<String> Function()? loadKnowledge})
    : _loadKnowledge =
          loadKnowledge ??
          (() => rootBundle.loadString('assets/content/meal-knowledge.json'));

  final Future<String> Function() _loadKnowledge;
  List<Map<String, dynamic>>? _entries;

  @override
  bool get isCloud => false;
  @override
  bool get supportsImages => false;

  @override
  Future<MealRecognition> recognize(MealPhoto photo) async =>
      throw const MealServiceException(
        'Nhận diện ảnh cần chế độ cloud đã đăng nhập và dịch vụ Gemini được cấu hình. Bạn vẫn có thể nhập món và thành phần.',
      );

  @override
  Future<MealAnalysis> analyze(MealDraft draft, UserProfile profile) async {
    if (_entries == null) {
      final data = jsonDecode(await _loadKnowledge()) as Map<String, dynamic>;
      _entries = (data['entries'] as List).cast<Map<String, dynamic>>();
    }
    final matched = _entries!
        .where(
          (entry) => draft.ingredients.any(
            (ingredient) => (entry['keywords'] as List).cast<String>().any(
              (keyword) => ingredientMatchesKeyword(ingredient.name, keyword),
            ),
          ),
        )
        .take(6)
        .toList();
    final references = matched
        .map((entry) => BookReference.fromJson(entry))
        .toList();
    return MealAnalysis(
      title: matched.isEmpty
          ? 'Cần thêm thông tin về món ăn'
          : 'Một góc nhìn từ sách',
      summary: matched.isEmpty
          ? 'Chưa tìm được đoạn sách đã đối chiếu phù hợp với thành phần bạn xác nhận. Hãy ghi cụ thể loại rau, đậu, ngũ cốc hoặc cách chế biến.'
          : 'Đã đối chiếu ${draft.ingredients.length} thành phần bạn xác nhận với ${matched.length} đoạn sách có nguồn. Đây là đối chiếu cục bộ, chưa phải phân tích Gemini.',
      highlights: matched.take(3).map((entry) {
        final foods = draft.ingredients.where(
          (ingredient) => (entry['keywords'] as List).cast<String>().any(
            (keyword) => ingredientMatchesKeyword(ingredient.name, keyword),
          ),
        );
        return '${foods.map((food) => food.name).join(', ')} — ${entry['title']}.';
      }).toList(),
      improvements: matched
          .map((entry) => entry['suggestion'] as String)
          .toSet()
          .take(2)
          .toList(),
      profileNote:
          'Mục tiêu của bạn: ${profile.goal.title}. ${profile.goal.suggestion} '
          'Hồ sơ hiện có tuổi, cân nặng và chiều cao, nhưng thiếu khẩu phần, dị ứng, bệnh sử và thuốc đang dùng; '
          'chế độ đối chiếu cục bộ không tính nhu cầu năng lượng hay đưa ra chỉ định riêng từ các số đo này.',
      limitations: const [
        'Đối chiếu sách cục bộ theo tên thành phần, không phải AI nhận diện hay tư vấn dinh dưỡng cá nhân.',
        'Không thể xác định lượng muối, đường, dầu, năng lượng hoặc chất gây dị ứng chỉ từ ảnh.',
        'Các chủ đề sức khỏe trong sách nói về thói quen ăn uống lâu dài; một bữa ăn không chứng minh tác dụng phòng hay điều trị bệnh.',
      ],
      references: references,
      healthConnections: matched
          .map(
            (entry) => HealthConnection(
              topic: (entry['healthTopics'] as List).join(' · '),
              explanation: entry['summary'] as String,
              referenceIds: [entry['id'] as String],
            ),
          )
          .toList(),
      mode: 'localBook',
    );
  }
}
