import 'dart:async' as async;

import 'package:flutter/material.dart';

import '../models/cooking_timer_model.dart';
import '../services/cooking_timer_service.dart';

class CookingTimerProvider extends ChangeNotifier {
  final CookingTimerService cookingTimerService;

  CookingTimerProvider({
    required this.cookingTimerService,
  });

  bool _isLoading = false;
  String? _errorMessage;
  String? _lastCompletedTimerTitle;

  final Map<String, _TimerRuntimeState> _runtimeStates = {};
  final Map<String, async.Timer> _activeTimers = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<CookingTimerModel>> getUserTimersStream(String userId) {
    return cookingTimerService.streamUserTimers(userId);
  }

  int getRemainingSeconds(CookingTimerModel timer) {
    return _runtimeStates[timer.id]?.remainingSeconds ?? timer.durationSeconds;
  }

  bool isRunning(String timerId) {
    return _runtimeStates[timerId]?.isRunning ?? false;
  }

  bool isCompleted(String timerId) {
    return _runtimeStates[timerId]?.isCompleted ?? false;
  }

  String? consumeCompletedTimerTitle() {
    final title = _lastCompletedTimerTitle;
    _lastCompletedTimerTitle = null;
    return title;
  }

  String formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');

    return '$minuteText:$secondText';
  }

  Future<bool> createTimer({
    required String userId,
    required String title,
    required String description,
    required int durationSeconds,
    String? linkedMealId,
    String? linkedMealName,
  }) async {
    _setLoading(true);

    try {
      await cookingTimerService.createTimer(
        userId: userId,
        title: title,
        description: description,
        durationSeconds: durationSeconds,
        linkedMealId: linkedMealId,
        linkedMealName: linkedMealName,
      );

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTimer(CookingTimerModel timer) async {
    _setLoading(true);

    try {
      await cookingTimerService.updateTimer(timer);

      resetTimer(timer);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to update timer. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteTimer(String timerId) async {
    _setLoading(true);

    try {
      _activeTimers[timerId]?.cancel();
      _activeTimers.remove(timerId);
      _runtimeStates.remove(timerId);

      await cookingTimerService.deleteTimer(timerId);

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = 'Unable to delete timer. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void startTimer(CookingTimerModel timer) {
    final state = _runtimeStates[timer.id] ??
        _TimerRuntimeState(
          remainingSeconds: timer.durationSeconds,
        );

    if (state.isRunning) return;

    if (state.remainingSeconds <= 0) {
      state.remainingSeconds = timer.durationSeconds;
    }

    state.isRunning = true;
    state.isCompleted = false;

    _runtimeStates[timer.id] = state;

    _activeTimers[timer.id]?.cancel();

    _activeTimers[timer.id] = async.Timer.periodic(
      const Duration(seconds: 1),
          (ticker) {
        if (state.remainingSeconds <= 1) {
          state.remainingSeconds = 0;
          state.isRunning = false;
          state.isCompleted = true;

          ticker.cancel();
          _activeTimers.remove(timer.id);

          _lastCompletedTimerTitle = timer.title;

          notifyListeners();
          return;
        }

        state.remainingSeconds--;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  void pauseTimer(String timerId) {
    final state = _runtimeStates[timerId];

    if (state == null) return;

    _activeTimers[timerId]?.cancel();
    _activeTimers.remove(timerId);

    state.isRunning = false;

    notifyListeners();
  }

  void resetTimer(CookingTimerModel timer) {
    _activeTimers[timer.id]?.cancel();
    _activeTimers.remove(timer.id);

    _runtimeStates[timer.id] = _TimerRuntimeState(
      remainingSeconds: timer.durationSeconds,
      isRunning: false,
      isCompleted: false,
    );

    notifyListeners();
  }

  Future<int> getTimerCount(String userId) async {
    try {
      return await cookingTimerService.getUserTimerCount(userId);
    } catch (_) {
      return 0;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }

    super.dispose();
  }
}

class _TimerRuntimeState {
  int remainingSeconds;
  bool isRunning;
  bool isCompleted;

  _TimerRuntimeState({
    required this.remainingSeconds,
    this.isRunning = false,
    this.isCompleted = false,
  });
}