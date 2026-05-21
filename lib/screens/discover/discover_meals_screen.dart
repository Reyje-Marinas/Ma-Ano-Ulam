import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/meal_card.dart';
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
                  'Discover Meals',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchMeals(),
                  decoration: InputDecoration(
                    hintText: 'Search meals, e.g. chicken, pasta...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
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
                    message: 'Finding meals for you...',
                  );
                }

                if (mealProvider.errorMessage != null) {
                  return EmptyStateWidget(
                    icon: Icons.wifi_off_outlined,
                    title: 'Unable to load meals',
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
                    title: 'No meals found',
                    subtitle: 'Try searching for another meal keyword.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: mealProvider.meals.length,
                  itemBuilder: (context, index) {
                    final meal = mealProvider.meals[index];

                    return MealCard(
                      meal: meal,
                      onTap: () => _openMealDetails(meal.id),
                      onFavoriteTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Favorites will be connected in the next milestone.',
                            ),
                          ),
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