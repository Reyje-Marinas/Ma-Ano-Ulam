import 'package:flutter/material.dart';

import '../models/favorite_meal_model.dart';
import '../models/meal_api_model.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService favoriteService;

  FavoriteProvider({
    required this.favoriteService,
  });

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<FavoriteMealModel>> getFavoritesStream(String userId) {
    return favoriteService.streamUserFavorites(userId);
  }

  Future<bool> saveFavorite({
    required String userId,
    required MealApiModel meal,
  }) async {
    _setLoading(true);

    try {
      final favorite = FavoriteMealModel.fromApi(
        userId: userId,
        meal: meal,
      );

      await favoriteService.saveFavorite(favorite);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to save favorite. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeFavorite(String favoriteId) async {
    _setLoading(true);

    try {
      await favoriteService.removeFavorite(favoriteId);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to remove favorite. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeFavoriteByMealId({
    required String userId,
    required String mealId,
  }) async {
    _setLoading(true);

    try {
      await favoriteService.removeFavoriteByMealId(
        userId: userId,
        mealId: mealId,
      );

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to remove favorite. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> isFavorite({
    required String userId,
    required String mealId,
  }) async {
    try {
      return await favoriteService.isFavorite(
        userId: userId,
        mealId: mealId,
      );
    } catch (_) {
      return false;
    }
  }

  Future<int> getFavoritesCount(String userId) async {
    try {
      return await favoriteService.getUserFavoritesCount(userId);
    } catch (_) {
      return 0;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}