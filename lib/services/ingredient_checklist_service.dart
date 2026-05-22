import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingredient_checklist_model.dart';

class IngredientChecklistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('ingredientChecklists');
  }

  String getDocumentId({
    required String userId,
    required String mealId,
  }) {
    return '${userId}_$mealId';
  }

  Stream<IngredientChecklistModel> streamChecklist({
    required String userId,
    required String mealId,
  }) {
    final documentId = getDocumentId(
      userId: userId,
      mealId: mealId,
    );

    return _collection.doc(documentId).snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return IngredientChecklistModel.empty(
          userId: userId,
          mealId: mealId,
        );
      }

      return IngredientChecklistModel.fromMap(
        document.id,
        document.data()!,
      );
    });
  }

  Future<void> setIngredientChecked({
    required String userId,
    required String mealId,
    required String ingredientName,
    required bool isChecked,
  }) async {
    final documentId = getDocumentId(
      userId: userId,
      mealId: mealId,
    );

    await _collection.doc(documentId).set(
      {
        'userId': userId,
        'mealId': mealId,
        'checkedIngredients': isChecked
            ? FieldValue.arrayUnion([ingredientName])
            : FieldValue.arrayRemove([ingredientName]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> resetChecklist({
    required String userId,
    required String mealId,
  }) async {
    final documentId = getDocumentId(
      userId: userId,
      mealId: mealId,
    );

    await _collection.doc(documentId).set(
      {
        'userId': userId,
        'mealId': mealId,
        'checkedIngredients': [],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}