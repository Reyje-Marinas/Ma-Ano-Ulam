import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/ingredient_checklist_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/meal_api_model.dart';
import '../../models/meal_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/meal_api_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../cooking/cooking_mode_screen.dart';
import '../planner/generate_plan_screen.dart';

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
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          Builder(
            builder: (context) {
              final meal = mealProvider.selectedMeal;

              if (meal == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                onPressed: () async {
                  final userId =
                      context.read<AppAuthProvider>().firebaseUser?.uid;

                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login first.'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                    return;
                  }

                  final success =
                  await context.read<FavoriteProvider>().saveFavorite(
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
                },
                icon: const Icon(
                  Icons.favorite_border,
                  color: AppColors.accentOrange,
                ),
              );
            },
          ),
        ],
      ),
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

  List<String> _getInstructionSteps() {
    final instructions = meal.instructions ?? '';

    if (instructions.trim().isEmpty) {
      return ['No cooking instructions available.'];
    }

    String cleanStepLabel(String text) {
      var cleaned = text.trim();

      cleaned = cleaned.replaceFirst(
        RegExp(
          r'^step\s*\d+\s*[:.)-]?',
          caseSensitive: false,
        ),
        '',
      );

      cleaned = cleaned.replaceFirst(
        RegExp(r'^\d+\s*[:.)-]?\s*'),
        '',
      );

      return cleaned.trim();
    }

    final normalizedInstructions = instructions
        .replaceAll('\r', '\n')
        .replaceAll(
      RegExp(
        r'\bstep\s*\d+\s*[:.)-]?',
        caseSensitive: false,
      ),
      '\n',
    );

    final lineSteps = normalizedInstructions
        .split('\n')
        .map(cleanStepLabel)
        .where((step) => step.isNotEmpty)
        .where(
          (step) => !step.toLowerCase().startsWith('watch after ad'),
    )
        .toList();

    if (lineSteps.length > 1) {
      return lineSteps;
    }

    final sentenceSteps = normalizedInstructions
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map(cleanStepLabel)
        .where((step) => step.isNotEmpty)
        .where(
          (step) => !step.toLowerCase().startsWith('watch after ad'),
    )
        .toList();

    if (sentenceSteps.isEmpty) {
      return ['No cooking instructions available.'];
    }

    return sentenceSteps;
  }

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
      builder: (bottomSheetContext) {
        return _AddToPlanSheet(
          userId: userId,
          meal: meal,
          parentContext: context,
        );
      },
    );
  }

  void _openCookingMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookingModeScreen(meal: meal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppAuthProvider>().firebaseUser?.uid;
    final steps = _getInstructionSteps();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          _MealHeaderCard(meal: meal),
          const SizedBox(height: 24),

          IngredientChecklistWidget(
            userId: userId,
            meal: meal,
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cooking Procedure',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => _openCookingMode(context),
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('Cook'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(
                      color: AppColors.primaryGreen,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...List.generate(
            steps.length,
                (index) => _ProcedureStepCard(
              stepNumber: index + 1,
              instruction: steps[index],
            ),
          ),

          const SizedBox(height: 24),

          _ActionSection(
            onStartCooking: () => _openCookingMode(context),
            onSaveMeal: () => _saveToFavorites(context),
            onAddToPlan: () => _showAddToPlanSheet(context),
          ),
        ],
      ),
    );
  }
}

class _MealHeaderCard extends StatelessWidget {
  final MealApiModel meal;

  const _MealHeaderCard({
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(26),
            ),
            child: CachedNetworkImage(
              imageUrl: meal.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  height: 220,
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
                  height: 220,
                  color: AppColors.lightOrange,
                  child: const Icon(
                    Icons.restaurant,
                    size: 70,
                    color: AppColors.accentOrange,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcedureStepCard extends StatelessWidget {
  final int stepNumber;
  final String instruction;

  const _ProcedureStepCard({
    required this.stepNumber,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.lightGreen,
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final VoidCallback onStartCooking;
  final VoidCallback onSaveMeal;
  final VoidCallback onAddToPlan;

  const _ActionSection({
    required this.onStartCooking,
    required this.onSaveMeal,
    required this.onAddToPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          CustomButton(
            text: 'Start Cooking Mode',
            onPressed: onStartCooking,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Save Meal',
            backgroundColor: AppColors.accentOrange,
            onPressed: onSaveMeal,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Add to Weekly Plan',
            onPressed: onAddToPlan,
          ),
        ],
      ),
    );
  }
}

class _AddToPlanSheet extends StatefulWidget {
  final String userId;
  final MealApiModel meal;
  final BuildContext parentContext;

  const _AddToPlanSheet({
    required this.userId,
    required this.meal,
    required this.parentContext,
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

  void _goToGeneratePlan() {
    Navigator.pop(context);

    Future.microtask(() {
      if (!widget.parentContext.mounted) return;

      Navigator.push(
        widget.parentContext,
        MaterialPageRoute(
          builder: (context) => const GeneratePlanScreen(),
        ),
      );
    });
  }

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
                const SizedBox(height: 22),
                CustomButton(
                  text: 'Generate Weekly Plan',
                  onPressed: _goToGeneratePlan,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Close',
                  backgroundColor: AppColors.textGray,
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