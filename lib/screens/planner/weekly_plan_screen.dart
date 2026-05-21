import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/planner_day_card.dart';
import '../../models/meal_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../discover/meal_detail_screen.dart';
import 'generate_plan_screen.dart';

class WeeklyPlanScreen extends StatelessWidget {
  const WeeklyPlanScreen({super.key});

  String _formatDateRange(MealPlanModel plan) {
    if (plan.days.isEmpty) {
      return '';
    }

    final start = plan.days.first.date;
    final end = plan.days.last.date;

    return '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}';
  }

  Future<void> _replaceMeal({
    required BuildContext context,
    required String userId,
    required int dayIndex,
    required String slot,
  }) async {
    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Replace Meal'),
          content: Text('Replace the $slot meal with a random meal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );

    if (shouldReplace != true || !context.mounted) return;

    final provider = context.read<MealPlanProvider>();

    final success = await provider.replaceMealWithRandom(
      userId: userId,
      dayIndex: dayIndex,
      slot: slot,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Meal replaced successfully.'
              : provider.errorMessage ?? 'Unable to replace meal.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  Future<void> _deleteMeal({
    required BuildContext context,
    required String userId,
    required int dayIndex,
    required String slot,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Meal'),
          content: Text('Remove the $slot meal from this day?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;

    final provider = context.read<MealPlanProvider>();

    final success = await provider.deleteMealFromPlan(
      userId: userId,
      dayIndex: dayIndex,
      slot: slot,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Meal removed from plan.'
              : provider.errorMessage ?? 'Unable to delete meal.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  Future<void> _clearPlan({
    required BuildContext context,
    required String userId,
  }) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Weekly Plan'),
          content: const Text('Are you sure you want to clear the whole plan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) return;

    final provider = context.read<MealPlanProvider>();

    final success = await provider.clearMealPlan(userId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Weekly plan cleared.'
              : provider.errorMessage ?? 'Unable to clear plan.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  void _openGeneratePlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GeneratePlanScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppAuthProvider>().firebaseUser?.uid;

    if (userId == null) {
      return const SafeArea(
        child: EmptyStateWidget(
          icon: Icons.lock_outline,
          title: 'Login required',
          subtitle: 'Please login to view your weekly meal plan.',
        ),
      );
    }

    return SafeArea(
      child: StreamBuilder<MealPlanModel?>(
        stream: context.read<MealPlanProvider>().getMealPlanStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(
              message: 'Loading weekly plan...',
            );
          }

          if (snapshot.hasError) {
            return const EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Unable to load plan',
              subtitle: 'Please check your connection and try again.',
            );
          }

          final plan = snapshot.data;

          if (plan == null || plan.days.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.calendar_month_outlined,
              title: 'No weekly plan yet',
              subtitle: 'Generate your first meal plan now.',
              buttonText: 'Generate Plan',
              onButtonPressed: () => _openGeneratePlan(context),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Weekly Plan',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateRange(plan),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Generate New',
                            onPressed: () => _openGeneratePlan(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Clear Plan',
                            backgroundColor: AppColors.errorRed,
                            onPressed: () {
                              _clearPlan(
                                context: context,
                                userId: userId,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: plan.days.length,
                  itemBuilder: (context, index) {
                    final day = plan.days[index];

                    return PlannerDayCard(
                      day: day,
                      dayIndex: index,
                      onViewMeal: (mealId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return MealDetailScreen(mealId: mealId);
                            },
                          ),
                        );
                      },
                      onReplaceMeal: (slot) {
                        _replaceMeal(
                          context: context,
                          userId: userId,
                          dayIndex: index,
                          slot: slot,
                        );
                      },
                      onDeleteMeal: (slot) {
                        _deleteMeal(
                          context: context,
                          userId: userId,
                          dayIndex: index,
                          slot: slot,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}