import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cooking_timer_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/ingredient_checklist_provider.dart';
import 'providers/meal_api_provider.dart';
import 'providers/meal_plan_provider.dart';
import 'services/auth_service.dart';
import 'services/cooking_timer_service.dart';
import 'services/favorite_service.dart';
import 'services/ingredient_checklist_service.dart';
import 'services/meal_api_service.dart';
import 'services/meal_plan_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(
            authService: AuthService(),
            userService: UserService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MealApiProvider(
            mealApiService: MealApiService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(
            favoriteService: FavoriteService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MealPlanProvider(
            mealPlanService: MealPlanService(),
            mealApiService: MealApiService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => IngredientChecklistProvider(
            checklistService: IngredientChecklistService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CookingTimerProvider(
            cookingTimerService: CookingTimerService(),
          ),
        ),
      ],
      child: const MealMateApp(),
    ),
  );
}