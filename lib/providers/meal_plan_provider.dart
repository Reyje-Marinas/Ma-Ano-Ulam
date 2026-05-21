import 'dart:math';

import 'package:flutter/material.dart';

import '../models/meal_api_model.dart';
import '../models/meal_plan_model.dart';
import '../services/meal_api_service.dart';
import '../services/meal_plan_service.dart';

class MealPlanProvider extends ChangeNotifier {
  final MealPlanService mealPlanService;
  final MealApiService mealApiService;

  MealPlanProvider({
    required this.mealPlanService,
    required this.mealApiService,
  });

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final List<String> _dayNames = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _categories = const [
    'Chicken',
    'Beef',
    'Seafood',
    'Vegetarian',
    'Dessert',
    'Pasta',
  ];

  Stream<MealPlanModel?> getMealPlanStream(String userId) {
    return mealPlanService.streamUserMealPlan(userId);
  }

  Future<bool> generateMealPlan({
    required String userId,
    required DateTime weekStartDate,
    required int numberOfDays,
    required String category,
    required List<String> selectedSlots,
  }) async {
    _setLoading(true);

    try {
      if (selectedSlots.isEmpty) {
        throw Exception('Please select at least one meal slot.');
      }

      final random = Random();

      final selectedCategory = category == 'Random'
          ? _categories[random.nextInt(_categories.length)]
          : category;

      final apiMeals = await mealApiService.getMealsByCategory(
        selectedCategory,
      );

      if (apiMeals.isEmpty) {
        throw Exception('No meals found for the selected category.');
      }

      apiMeals.shuffle();

      final days = <MealPlanDayModel>[];

      for (int dayIndex = 0; dayIndex < numberOfDays; dayIndex++) {
        final date = weekStartDate.add(Duration(days: dayIndex));
        final dayName = _dayNames[(date.weekday - 1) % 7];

        final meals = <String, MealPlanMealModel>{};

        for (final slot in selectedSlots) {
          final meal = apiMeals[random.nextInt(apiMeals.length)];
          meals[slot] = MealPlanMealModel.fromApi(meal);
        }

        days.add(
          MealPlanDayModel(
            dayName: dayName,
            date: date,
            meals: meals,
          ),
        );
      }

      final plan = MealPlanModel(
        id: userId,
        userId: userId,
        weekStartDate: weekStartDate,
        days: days,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mealPlanService.saveMealPlan(plan);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> replaceMealWithRandom({
    required String userId,
    required int dayIndex,
    required String slot,
  }) async {
    _setLoading(true);

    try {
      final plan = await mealPlanService.getUserMealPlan(userId);

      if (plan == null) {
        throw Exception('No meal plan found.');
      }

      final randomMeal = await mealApiService.getRandomMeal();

      if (randomMeal == null) {
        throw Exception('Unable to get a replacement meal.');
      }

      final updatedDays = List<MealPlanDayModel>.from(plan.days);
      final selectedDay = updatedDays[dayIndex];

      final updatedMeals = Map<String, MealPlanMealModel>.from(
        selectedDay.meals,
      );

      updatedMeals[slot] = MealPlanMealModel.fromApi(randomMeal);

      updatedDays[dayIndex] = selectedDay.copyWith(
        meals: updatedMeals,
      );

      final updatedPlan = plan.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );

      await mealPlanService.saveMealPlan(updatedPlan);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteMealFromPlan({
    required String userId,
    required int dayIndex,
    required String slot,
  }) async {
    _setLoading(true);

    try {
      final plan = await mealPlanService.getUserMealPlan(userId);

      if (plan == null) {
        throw Exception('No meal plan found.');
      }

      final updatedDays = List<MealPlanDayModel>.from(plan.days);
      final selectedDay = updatedDays[dayIndex];

      final updatedMeals = Map<String, MealPlanMealModel>.from(
        selectedDay.meals,
      );

      updatedMeals.remove(slot);

      updatedDays[dayIndex] = selectedDay.copyWith(
        meals: updatedMeals,
      );

      final updatedPlan = plan.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );

      await mealPlanService.saveMealPlan(updatedPlan);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> addMealToExistingPlan({
    required String userId,
    required int dayIndex,
    required String slot,
    required MealApiModel meal,
  }) async {
    _setLoading(true);

    try {
      final plan = await mealPlanService.getUserMealPlan(userId);

      if (plan == null) {
        throw Exception('Please generate a weekly plan first.');
      }

      final updatedDays = List<MealPlanDayModel>.from(plan.days);

      if (dayIndex < 0 || dayIndex >= updatedDays.length) {
        throw Exception('Invalid day selected.');
      }

      final selectedDay = updatedDays[dayIndex];

      final updatedMeals = Map<String, MealPlanMealModel>.from(
        selectedDay.meals,
      );

      updatedMeals[slot] = MealPlanMealModel.fromApi(meal);

      updatedDays[dayIndex] = selectedDay.copyWith(
        meals: updatedMeals,
      );

      final updatedPlan = plan.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );

      await mealPlanService.saveMealPlan(updatedPlan);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> clearMealPlan(String userId) async {
    _setLoading(true);

    try {
      await mealPlanService.deleteMealPlan(userId);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to clear meal plan.';
      _setLoading(false);
      return false;
    }
  }

  Future<int> getMealPlanCount(String userId) async {
    try {
      return await mealPlanService.getUserMealPlanCount(userId);
    } catch (_) {
      return 0;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}