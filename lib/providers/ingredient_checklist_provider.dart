import 'package:flutter/material.dart';

import '../models/ingredient_checklist_model.dart';
import '../services/ingredient_checklist_service.dart';

class IngredientChecklistProvider extends ChangeNotifier {
  final IngredientChecklistService checklistService;

  IngredientChecklistProvider({
    required this.checklistService,
  });

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<IngredientChecklistModel> getChecklistStream({
    required String userId,
    required String mealId,
  }) {
    return checklistService.streamChecklist(
      userId: userId,
      mealId: mealId,
    );
  }

  Future<bool> setIngredientChecked({
    required String userId,
    required String mealId,
    required String ingredientName,
    required bool isChecked,
  }) async {
    _setLoading(true);

    try {
      await checklistService.setIngredientChecked(
        userId: userId,
        mealId: mealId,
        ingredientName: ingredientName,
        isChecked: isChecked,
      );

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to update ingredient checklist.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetChecklist({
    required String userId,
    required String mealId,
  }) async {
    _setLoading(true);

    try {
      await checklistService.resetChecklist(
        userId: userId,
        mealId: mealId,
      );

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to reset checklist.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}