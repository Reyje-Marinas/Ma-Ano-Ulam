import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientChecklistModel {
  final String id;
  final String userId;
  final String mealId;
  final List<String> checkedIngredients;
  final DateTime? updatedAt;

  const IngredientChecklistModel({
    required this.id,
    required this.userId,
    required this.mealId,
    required this.checkedIngredients,
    this.updatedAt,
  });

  factory IngredientChecklistModel.empty({
    required String userId,
    required String mealId,
  }) {
    return IngredientChecklistModel(
      id: '${userId}_$mealId',
      userId: userId,
      mealId: mealId,
      checkedIngredients: const [],
      updatedAt: null,
    );
  }

  factory IngredientChecklistModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return IngredientChecklistModel(
      id: id,
      userId: map['userId'] ?? '',
      mealId: map['mealId'] ?? '',
      checkedIngredients: List<String>.from(
        map['checkedIngredients'] ?? [],
      ),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}