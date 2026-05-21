import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/meal_api_model.dart';
import '../../providers/meal_api_provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;

  const MealDetailScreen({
    super.key,
    required this.mealId,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<MealApiProvider>().getMealDetails(widget.mealId);
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (mounted) {
        context.read<MealApiProvider>().clearSelectedMeal();
      }
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealApiProvider>();

    return Scaffold(
      body: Builder(
        builder: (context) {
          if (mealProvider.isLoading) {
            return const LoadingWidget(
              message: 'Loading meal details...',
            );
          }

          if (mealProvider.errorMessage != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Unable to load details',
              subtitle: mealProvider.errorMessage!,
              buttonText: 'Go Back',
              onButtonPressed: () => Navigator.pop(context),
            );
          }

          final meal = mealProvider.selectedMeal;

          if (meal == null) {
            return EmptyStateWidget(
              icon: Icons.restaurant_outlined,
              title: 'Meal not found',
              subtitle: 'The selected meal could not be loaded.',
              buttonText: 'Go Back',
              onButtonPressed: () => Navigator.pop(context),
            );
          }

          return _MealDetailContent(meal: meal);
        },
      ),
    );
  }
}

class _MealDetailContent extends StatelessWidget {
  final MealApiModel meal;

  const _MealDetailContent({
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
          flexibleSpace: FlexibleSpaceBar(
            background: CachedNetworkImage(
              imageUrl: meal.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  color: AppColors.lightOrange,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  color: AppColors.lightOrange,
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: AppColors.accentOrange,
                  ),
                );
              },
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Favorites will be connected in the next milestone.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.favorite_border,
                color: AppColors.accentOrange,
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (meal.category != null)
                      _InfoChip(
                        label: meal.category!,
                        icon: Icons.category_outlined,
                        color: AppColors.primaryGreen,
                      ),
                    if (meal.area != null)
                      _InfoChip(
                        label: meal.area!,
                        icon: Icons.public,
                        color: AppColors.accentOrange,
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _IngredientsCard(ingredients: meal.ingredients),
                const SizedBox(height: 30),
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    meal.instructions ?? 'No instructions available.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Save to Favorites',
                  backgroundColor: AppColors.accentOrange,
                  onPressed: () async {
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

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Saved to favorites.'
                              : context.read<FavoriteProvider>().errorMessage ??
                              'Unable to save favorite.',
                        ),
                        backgroundColor:
                        success ? AppColors.primaryGreen : AppColors.errorRed,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'Add to Weekly Plan',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Meal planner will be connected after favorites.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide.none,
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  final List<MealIngredient> ingredients;

  const _IngredientsCard({
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'No ingredients available.',
          style: TextStyle(color: AppColors.textGray),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: ingredients.map((ingredient) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  ingredient.measure,
                  style: const TextStyle(
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}