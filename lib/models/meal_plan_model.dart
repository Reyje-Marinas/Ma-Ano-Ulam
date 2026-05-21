import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_api_model.dart';

class MealPlanModel {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final List<MealPlanDayModel> days;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MealPlanModel({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.days,
    required this.createdAt,
    this.updatedAt,
  });

  MealPlanModel copyWith({
    String? id,
    String? userId,
    DateTime? weekStartDate,
    List<MealPlanDayModel>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'days': days.map((day) => day.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory MealPlanModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    final rawDays = map['days'] as List? ?? [];

    return MealPlanModel(
      id: id,
      userId: map['userId'] ?? '',
      weekStartDate: map['weekStartDate'] != null
          ? (map['weekStartDate'] as Timestamp).toDate()
          : DateTime.now(),
      days: rawDays.map((day) {
        return MealPlanDayModel.fromMap(
          Map<String, dynamic>.from(day as Map),
        );
      }).toList(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class MealPlanDayModel {
  final String dayName;
  final DateTime date;
  final Map<String, MealPlanMealModel> meals;

  const MealPlanDayModel({
    required this.dayName,
    required this.date,
    required this.meals,
  });

  MealPlanDayModel copyWith({
    String? dayName,
    DateTime? date,
    Map<String, MealPlanMealModel>? meals,
  }) {
    return MealPlanDayModel(
      dayName: dayName ?? this.dayName,
      date: date ?? this.date,
      meals: meals ?? this.meals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayName': dayName,
      'date': Timestamp.fromDate(date),
      'meals': meals.map(
            (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory MealPlanDayModel.fromMap(Map<String, dynamic> map) {
    final rawMeals = Map<String, dynamic>.from(map['meals'] ?? {});

    return MealPlanDayModel(
      dayName: map['dayName'] ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      meals: rawMeals.map((key, value) {
        return MapEntry(
          key,
          MealPlanMealModel.fromMap(
            Map<String, dynamic>.from(value as Map),
          ),
        );
      }),
    );
  }
}

class MealPlanMealModel {
  final String mealId;
  final String mealName;
  final String imageUrl;
  final String? category;
  final String? area;

  const MealPlanMealModel({
    required this.mealId,
    required this.mealName,
    required this.imageUrl,
    this.category,
    this.area,
  });

  factory MealPlanMealModel.fromApi(MealApiModel meal) {
    return MealPlanMealModel(
      mealId: meal.id,
      mealName: meal.name,
      imageUrl: meal.imageUrl,
      category: meal.category,
      area: meal.area,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mealId': mealId,
      'mealName': mealName,
      'imageUrl': imageUrl,
      'category': category,
      'area': area,
    };
  }

  factory MealPlanMealModel.fromMap(Map<String, dynamic> map) {
    return MealPlanMealModel(
      mealId: map['mealId'] ?? '',
      mealName: map['mealName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'],
      area: map['area'],
    );
  }
}