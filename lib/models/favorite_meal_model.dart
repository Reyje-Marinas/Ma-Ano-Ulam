import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_api_model.dart';

class FavoriteMealModel {
  final String id;
  final String userId;
  final String mealId;
  final String mealName;
  final String imageUrl;
  final String? category;
  final String? area;
  final String? instructions;
  final DateTime createdAt;

  const FavoriteMealModel({
    required this.id,
    required this.userId,
    required this.mealId,
    required this.mealName,
    required this.imageUrl,
    this.category,
    this.area,
    this.instructions,
    required this.createdAt,
  });

  factory FavoriteMealModel.fromApi({
    required String userId,
    required MealApiModel meal,
  }) {
    final favoriteId = '${userId}_${meal.id}';

    return FavoriteMealModel(
      id: favoriteId,
      userId: userId,
      mealId: meal.id,
      mealName: meal.name,
      imageUrl: meal.imageUrl,
      category: meal.category,
      area: meal.area,
      instructions: meal.instructions,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mealId': mealId,
      'mealName': mealName,
      'imageUrl': imageUrl,
      'category': category,
      'area': area,
      'instructions': instructions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FavoriteMealModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return FavoriteMealModel(
      id: id,
      userId: map['userId'] ?? '',
      mealId: map['mealId'] ?? '',
      mealName: map['mealName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'],
      area: map['area'],
      instructions: map['instructions'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}