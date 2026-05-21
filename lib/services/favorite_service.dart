import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/favorite_meal_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _favoritesCollection {
    return _firestore.collection('favorites');
  }

  String getFavoriteDocumentId({
    required String userId,
    required String mealId,
  }) {
    return '${userId}_$mealId';
  }

  Stream<List<FavoriteMealModel>> streamUserFavorites(String userId) {
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final favorites = snapshot.docs.map((doc) {
        return FavoriteMealModel.fromMap(doc.id, doc.data());
      }).toList();

      favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return favorites;
    });
  }

  Future<void> saveFavorite(FavoriteMealModel favorite) async {
    await _favoritesCollection.doc(favorite.id).set(favorite.toMap());
  }

  Future<void> removeFavorite(String favoriteId) async {
    await _favoritesCollection.doc(favoriteId).delete();
  }

  Future<void> removeFavoriteByMealId({
    required String userId,
    required String mealId,
  }) async {
    final favoriteId = getFavoriteDocumentId(
      userId: userId,
      mealId: mealId,
    );

    await removeFavorite(favoriteId);
  }

  Future<bool> isFavorite({
    required String userId,
    required String mealId,
  }) async {
    final favoriteId = getFavoriteDocumentId(
      userId: userId,
      mealId: mealId,
    );

    final document = await _favoritesCollection.doc(favoriteId).get();

    return document.exists;
  }

  Future<int> getUserFavoritesCount(String userId) async {
    final snapshot = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }
}