import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/ingredient_checklist_model.dart';
import '../../models/meal_api_model.dart';
import '../../models/meal_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/ingredient_checklist_provider.dart';
import '../../providers/meal_api_provider.dart';
import '../../providers/meal_plan_provider.dart';

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
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealApiProvider>();

    return Scaffold(
      body: Builder(
        builder: (context) {
          if (mealProvider.isLoading) {
            return const LoadingWidget(
              message: 'Loading recipe details...',
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
              title: 'Recipe not found',
              subtitle: 'The selected recipe could not be loaded.',
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

  Future<void> _saveToFavorites(BuildContext context) async {
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
              ? 'Saved to saved meals.'
              : context.read<FavoriteProvider>().errorMessage ??
              'Unable to save meal.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  void _showAddToPlanSheet(BuildContext context) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return _AddToPlanSheet(
          userId: userId,
          meal: meal,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppAuthProvider>().firebaseUser?.uid;

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
              onPressed: () => _saveToFavorites(context),
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
                _IngredientChecklistCard(
                  userId: userId,
                  meal: meal,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Cooking Procedure',
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
                  text: 'Save Meal',
                  backgroundColor: AppColors.accentOrange,
                  onPressed: () => _saveToFavorites(context),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'Add to Weekly Plan',
                  onPressed: () => _showAddToPlanSheet(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IngredientChecklistCard extends StatelessWidget {
  final String? userId;
  final MealApiModel meal;

  const _IngredientChecklistCard({
    required this.userId,
    required this.meal,
  });

  Future<void> _resetChecklist(BuildContext context) async {
    if (userId == null) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Checklist'),
          content: const Text(
            'Are you sure you want to uncheck all ingredients?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Reset',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReset != true || !context.mounted) return;

    final provider = context.read<IngredientChecklistProvider>();

    final success = await provider.resetChecklist(
      userId: userId!,
      mealId: meal.id,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Checklist reset.'
              : provider.errorMessage ?? 'Unable to reset checklist.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = meal.ingredients;

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

    if (userId == null) {
      return _ChecklistContent(
        meal: meal,
        checklist: IngredientChecklistModel.empty(
          userId: '',
          mealId: meal.id,
        ),
        isReadOnly: true,
        onReset: null,
      );
    }

    return StreamBuilder<IngredientChecklistModel>(
      stream: context
          .read<IngredientChecklistProvider>()
          .getChecklistStream(
        userId: userId!,
        mealId: meal.id,
      ),
      builder: (context, snapshot) {
        final checklist = snapshot.data ??
            IngredientChecklistModel.empty(
              userId: userId!,
              mealId: meal.id,
            );

        return _ChecklistContent(
          meal: meal,
          checklist: checklist,
          isReadOnly: false,
          onReset: () => _resetChecklist(context),
        );
      },
    );
  }
}

class _ChecklistContent extends StatelessWidget {
  final MealApiModel meal;
  final IngredientChecklistModel checklist;
  final bool isReadOnly;
  final VoidCallback? onReset;

  const _ChecklistContent({
    required this.meal,
    required this.checklist,
    required this.isReadOnly,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final checkedSet = checklist.checkedIngredients.toSet();
    final total = meal.ingredients.length;
    final checkedCount = meal.ingredients
        .where((ingredient) => checkedSet.contains(ingredient.name))
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ingredient Checklist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (!isReadOnly)
                TextButton(
                  onPressed: onReset,
                  child: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$checkedCount of $total ingredients checked',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : checkedCount / total,
              minHeight: 8,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...meal.ingredients.map((ingredient) {
            final isChecked = checkedSet.contains(ingredient.name);

            return CheckboxListTile(
              value: isChecked,
              activeColor: AppColors.primaryGreen,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                ingredient.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  decoration: isChecked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: ingredient.measure.trim().isEmpty
                  ? null
                  : Text(
                ingredient.measure,
                style: const TextStyle(
                  color: AppColors.textGray,
                ),
              ),
              onChanged: isReadOnly
                  ? null
                  : (value) async {
                final userId =
                    context.read<AppAuthProvider>().firebaseUser?.uid;

                if (userId == null) return;

                final provider =
                context.read<IngredientChecklistProvider>();

                final success = await provider.setIngredientChecked(
                  userId: userId,
                  mealId: meal.id,
                  ingredientName: ingredient.name,
                  isChecked: value ?? false,
                );

                if (!context.mounted || success) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage ??
                          'Unable to update checklist.',
                    ),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _AddToPlanSheet extends StatefulWidget {
  final String userId;
  final MealApiModel meal;

  const _AddToPlanSheet({
    required this.userId,
    required this.meal,
  });

  @override
  State<_AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends State<_AddToPlanSheet> {
  int? _selectedDayIndex;
  String _selectedSlot = 'Breakfast';

  final List<String> _slots = const [
    'Breakfast',
    'Lunch',
    'Dinner',
  ];

  Future<void> _addToPlan() async {
    final provider = context.read<MealPlanProvider>();

    final success = await provider.addMealToExistingPlan(
      userId: widget.userId,
      dayIndex: _selectedDayIndex ?? 0,
      slot: _selectedSlot,
      meal: widget.meal,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Meal added to weekly plan.'
              : provider.errorMessage ?? 'Unable to add meal to plan.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MealPlanModel?>(
      stream: context.read<MealPlanProvider>().getMealPlanStream(widget.userId),
      builder: (context, snapshot) {
        final plan = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          );
        }

        if (plan == null || plan.days.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 58,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No weekly plan yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Generate a weekly plan first before adding meals manually.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add to Weekly Plan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<int>(
                value: _selectedDayIndex ?? 0,
                decoration: const InputDecoration(
                  labelText: 'Select Day',
                ),
                items: List.generate(plan.days.length, (index) {
                  final day = plan.days[index];

                  return DropdownMenuItem(
                    value: index,
                    child: Text(day.dayName),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedDayIndex = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _selectedSlot,
                decoration: const InputDecoration(
                  labelText: 'Meal Slot',
                ),
                items: _slots.map((slot) {
                  return DropdownMenuItem(
                    value: slot,
                    child: Text(slot),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedSlot = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Add to Plan',
                isLoading: context.watch<MealPlanProvider>().isLoading,
                onPressed: _addToPlan,
              ),
            ],
          ),
        );
      },
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