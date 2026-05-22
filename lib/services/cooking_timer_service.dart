import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cooking_timer_model.dart';

class CookingTimerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _timersCollection {
    return _firestore.collection('cookingTimers');
  }

  Stream<List<CookingTimerModel>> streamUserTimers(String userId) {
    return _timersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final timers = snapshot.docs.map((doc) {
        return CookingTimerModel.fromMap(doc.id, doc.data());
      }).toList();

      timers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return timers;
    });
  }

  Future<void> createTimer({
    required String userId,
    required String title,
    required String description,
    required int durationSeconds,
    String? linkedMealId,
    String? linkedMealName,
  }) async {
    final document = _timersCollection.doc();

    final timer = CookingTimerModel(
      id: document.id,
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      durationSeconds: durationSeconds,
      linkedMealId: linkedMealId,
      linkedMealName: linkedMealName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await document.set(timer.toMap());
  }

  Future<void> updateTimer(CookingTimerModel timer) async {
    await _timersCollection.doc(timer.id).update(
      timer.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  Future<void> deleteTimer(String timerId) async {
    await _timersCollection.doc(timerId).delete();
  }

  Future<int> getUserTimerCount(String userId) async {
    final snapshot = await _timersCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }
}