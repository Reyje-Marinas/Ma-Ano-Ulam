import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal_api_model.dart';

class MealApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<MealApiModel>> searchMeals(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/search.php?s=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search meals.');
    }

    final data = jsonDecode(response.body);
    final meals = data['meals'];

    if (meals == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(meals)
        .map(MealApiModel.fromJson)
        .toList();
  }

  Future<List<MealApiModel>> getMealsByCategory(String category) async {
    final uri = Uri.parse(
      '$_baseUrl/filter.php?c=${Uri.encodeComponent(category)}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load meals by category.');
    }

    final data = jsonDecode(response.body);
    final meals = data['meals'];

    if (meals == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(meals).map((json) {
      return MealApiModel.fromJson({
        ...json,
        'strCategory': category,
      });
    }).toList();
  }

  Future<MealApiModel?> getMealDetails(String mealId) async {
    final uri = Uri.parse('$_baseUrl/lookup.php?i=$mealId');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load meal details.');
    }

    final data = jsonDecode(response.body);
    final meals = data['meals'];

    if (meals == null || meals.isEmpty) {
      return null;
    }

    return MealApiModel.fromJson(meals[0]);
  }

  Future<MealApiModel?> getRandomMeal() async {
    final uri = Uri.parse('$_baseUrl/random.php');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load random meal.');
    }

    final data = jsonDecode(response.body);
    final meals = data['meals'];

    if (meals == null || meals.isEmpty) {
      return null;
    }

    return MealApiModel.fromJson(meals[0]);
  }
}