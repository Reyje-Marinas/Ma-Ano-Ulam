import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/meal_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/meal_api_provider.dart';
import 'meal_detail_screen.dart';

class DiscoverMealsScreen extends StatefulWidget {
  const DiscoverMealsScreen({super.key});

  @override
  State<DiscoverMealsScreen> createState() => _DiscoverMealsScreenState();
}

class _DiscoverMealsScreenState extends State<DiscoverMealsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<MealApiProvider>().loadInitialMeals();
    });
  }

  Future<void> _searchMeals() async {
    FocusScope.of(context).unfocus();

    await context.read<MealApiProvider>().searchMeals(
      _searchController.text,
    );
  }

  void _openMealDetails(String mealId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return MealDetailScreen(mealId: mealId);
        },
      ),
    );
  }

  Future<void> _saveMealToFavorites(meal) async {
    final userId = context.read<AppAuthProvider>().firebaseUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final success = await context.read<FavoriteProvider>().saveFavorite(
      userId: userId,
      meal: meal,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Saved to saved meals.'
              : context.read<FavoriteProvider>().errorMessage ??
              'Unable to save meal.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealApiProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover Recipes',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search meals and recipes from TheMealDB.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchMeals(),
                  decoration: InputDecoration(
                    hintText: 'Search ulam, pasta, chicken...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _searchMeals,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mealProvider.categories.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(width: 10);
                    },
                    itemBuilder: (context, index) {
                      final category = mealProvider.categories[index];
                      final isSelected =
                          category == mealProvider.selectedCategory;

                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color:
                          isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.borderGray,
                          ),
                        ),
                        onSelected: (_) {
                          _searchController.clear();

                          context
                              .read<MealApiProvider>()
                              .getMealsByCategory(category);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(
              builder: (context) {
                if (mealProvider.isLoading) {
                  return const LoadingWidget(
                    message: 'Finding recipes for you...',
                  );
                }

                if (mealProvider.errorMessage != null) {
                  return EmptyStateWidget(
                    icon: Icons.wifi_off_outlined,
                    title: 'Unable to load recipes',
                    subtitle: mealProvider.errorMessage!,
                    buttonText: 'Try Again',
                    onButtonPressed: () {
                      context.read<MealApiProvider>().loadInitialMeals();
                    },
                  );
                }

                if (mealProvider.meals.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off_outlined,
                    title: 'No recipes found',
                    subtitle: 'Try searching for another meal keyword.',
                  );
                }

                final userId = context.read<AppAuthProvider>().firebaseUser?.uid;

                if (userId == null) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: mealProvider.meals.length,
                    itemBuilder: (context, index) {
                      final meal = mealProvider.meals[index];

                      return MealCard(
                        meal: meal,
                        isFavorite: false,
                        onTap: () => _openMealDetails(meal.id),
                        onFavoriteTap: () => _saveMealToFavorites(meal),
                      );
                    },
                  );
                }

                return StreamBuilder<Set<String>>(
                  stream: context.read<FavoriteProvider>().getFavoriteMealIdsStream(userId),
                  builder: (context, favoriteSnapshot) {
                    final favoriteMealIds = favoriteSnapshot.data ?? <String>{};

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: mealProvider.meals.length,
                      itemBuilder: (context, index) {
                        final meal = mealProvider.meals[index];
                        final isFavorite = favoriteMealIds.contains(meal.id);

                        return MealCard(
                          meal: meal,
                          isFavorite: isFavorite,
                          onTap: () => _openMealDetails(meal.id),
                          onFavoriteTap: () => _saveMealToFavorites(meal),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}