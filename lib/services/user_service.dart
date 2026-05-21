import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Future<void> createUserProfile(AppUserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<AppUserModel?> getUserProfile(String uid) async {
    final document = await _usersCollection.doc(uid).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return AppUserModel.fromMap(document.data()!);
  }

  Future<void> updateUserName({
    required String uid,
    required String name,
  }) async {
    await _usersCollection.doc(uid).update({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}