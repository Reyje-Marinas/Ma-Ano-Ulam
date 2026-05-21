import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService authService;
  final UserService userService;

  AppAuthProvider({
    required this.authService,
    required this.userService,
  }) {
    _authSubscription = authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      notifyListeners();
    });
  }

  User? _firebaseUser;
  AppUserModel? _appUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  User? get firebaseUser => _firebaseUser ?? authService.currentUser;
  AppUserModel? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => firebaseUser != null;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final credential = await authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      final appUser = AppUserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      await userService.createUserProfile(appUser);

      _firebaseUser = user;
      _appUser = appUser;
      _errorMessage = null;
      _setLoading(false);

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseAuthError(error);
      _setLoading(false);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final credential = await authService.loginWithEmail(
        email: email,
        password: password,
      );

      _firebaseUser = credential.user;

      if (_firebaseUser != null) {
        _appUser = await userService.getUserProfile(_firebaseUser!.uid);
      }

      _errorMessage = null;
      _setLoading(false);

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseAuthError(error);
      _setLoading(false);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadUserProfile() async {
    final user = firebaseUser;

    if (user == null) return;

    _appUser = await userService.getUserProfile(user.uid);
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    _firebaseUser = null;
    _appUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}