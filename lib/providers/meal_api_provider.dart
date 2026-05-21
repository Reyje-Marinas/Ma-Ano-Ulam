import 'package:flutter/material.dart';

import '../models/meal_api_model.dart';
import '../services/meal_api_service.dart';

class MealApiProvider extends ChangeNotifier {
  final MealApiService mealApiService;

  MealApiProvider({
    required this.mealApiService,
  });

  List<MealApiModel> _meals = [];
  MealApiModel? _selectedMeal;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Chicken';

  List<MealApiModel> get meals => _meals;
  MealApiModel? get selectedMeal => _selectedMeal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  final List<String> categories = const [
    'Chicken',
    'Beef',
    'Seafood',
    'Vegetarian',
    'Dessert',
    'Pasta',
  ];

  Future<void> loadInitialMeals() async {
    if (_meals.isNotEmpty) return;

    await getMealsByCategory(_selectedCategory);
  }

  Future<void> searchMeals(String query) async {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      await getMealsByCategory(_selectedCategory);
      return;
    }

    _setLoading(true);

    try {
      _meals = await mealApiService.searchMeals(cleanedQuery);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Unable to search meals. Please try again.';
    }

    _setLoading(false);
  }

  Future<void> getMealsByCategory(String category) async {
    _selectedCategory = category;
    _setLoading(true);

    try {
      _meals = await mealApiService.getMealsByCategory(category);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Unable to load meals. Please check your connection.';
    }

    _setLoading(false);
  }

  Future<void> getMealDetails(String mealId) async {
    _selectedMeal = null;
    _setLoading(true);

    try {
      _selectedMeal = await mealApiService.getMealDetails(mealId);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Unable to load meal details.';
    }

    _setLoading(false);
  }

  Future<MealApiModel?> getRandomMeal() async {
    _setLoading(true);

    try {
      final meal = await mealApiService.getRandomMeal();
      _errorMessage = null;
      _setLoading(false);
      return meal;
    } catch (error) {
      _errorMessage = 'Unable to load random meal.';
      _setLoading(false);
      return null;
    }
  }

  void clearSelectedMeal() {
    _selectedMeal = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}