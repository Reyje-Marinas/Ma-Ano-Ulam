import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_plan_model.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _mealPlansCollection {
    return _firestore.collection('mealPlans');
  }

  String getMealPlanDocumentId(String userId) {
    return userId;
  }

  Stream<MealPlanModel?> streamUserMealPlan(String userId) {
    return _mealPlansCollection
        .doc(getMealPlanDocumentId(userId))
        .snapshots()
        .map((document) {
      if (!document.exists || document.data() == null) {
        return null;
      }

      return MealPlanModel.fromMap(
        document.id,
        document.data()!,
      );
    });
  }

  Future<MealPlanModel?> getUserMealPlan(String userId) async {
    final document = await _mealPlansCollection
        .doc(getMealPlanDocumentId(userId))
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return MealPlanModel.fromMap(
      document.id,
      document.data()!,
    );
  }

  Future<void> saveMealPlan(MealPlanModel plan) async {
    await _mealPlansCollection
        .doc(getMealPlanDocumentId(plan.userId))
        .set(plan.toMap());
  }

  Future<void> deleteMealPlan(String userId) async {
    await _mealPlansCollection.doc(getMealPlanDocumentId(userId)).delete();
  }

  Future<int> getUserMealPlanCount(String userId) async {
    final document = await _mealPlansCollection
        .doc(getMealPlanDocumentId(userId))
        .get();

    return document.exists ? 1 : 0;
  }
}