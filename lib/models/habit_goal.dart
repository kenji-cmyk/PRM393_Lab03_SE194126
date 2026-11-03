enum HabitGoal { addVegetables, recordMeals, readDaily }

extension HabitGoalContent on HabitGoal {
  String get title => switch (this) {
    HabitGoal.addVegetables => 'Thêm rau vào bữa ăn',
    HabitGoal.recordMeals => 'Ghi lại bữa ăn',
    HabitGoal.readDaily => 'Đọc 5 phút mỗi ngày',
  };

  String get description => switch (this) {
    HabitGoal.addVegetables => 'Một mục tiêu nhỏ cho hôm nay.',
    HabitGoal.recordMeals => 'Quan sát thói quen của mình.',
    HabitGoal.readDaily => 'Học từng chút về thực phẩm.',
  };

  String get suggestion => switch (this) {
    HabitGoal.addVegetables => 'Thêm rau lá hoặc một loại đậu vào bữa trưa.',
    HabitGoal.recordMeals =>
      'Bắt đầu với bữa ăn gần nhất và ghi lại điều bạn nhớ.',
    HabitGoal.readDaily => 'Dành 5 phút hôm nay để tìm hiểu thêm về thực phẩm.',
  };
}
