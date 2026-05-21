import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/meal_plan_model.dart';
import '../constants/app_colors.dart';

class PlannerDayCard extends StatelessWidget {
  final MealPlanDayModel day;
  final int dayIndex;
  final void Function(String mealId) onViewMeal;
  final void Function(String slot) onReplaceMeal;
  final void Function(String slot) onDeleteMeal;

  const PlannerDayCard({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.onViewMeal,
    required this.onReplaceMeal,
    required this.onDeleteMeal,
  });

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final slots = ['Breakfast', 'Lunch', 'Dinner'];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                day.dayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(day.date),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...slots.where((slot) => day.meals.containsKey(slot)).map((slot) {
            final meal = day.meals[slot]!;

            return _PlannerMealRow(
              slot: slot,
              meal: meal,
              onView: () => onViewMeal(meal.mealId),
              onReplace: () => onReplaceMeal(slot),
              onDelete: () => onDeleteMeal(slot),
            );
          }),
        ],
      ),
    );
  }
}

class _PlannerMealRow extends StatelessWidget {
  final String slot;
  final MealPlanMealModel meal;
  final VoidCallback onView;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const _PlannerMealRow({
    required this.slot,
    required this.meal,
    required this.onView,
    required this.onReplace,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: meal.imageUrl,
              height: 54,
              width: 54,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  height: 54,
                  width: 54,
                  color: AppColors.lightOrange,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  height: 54,
                  width: 54,
                  color: AppColors.lightOrange,
                  child: const Icon(
                    Icons.restaurant,
                    color: AppColors.accentOrange,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onView,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.mealName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Replace meal',
            onPressed: onReplace,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primaryGreen,
            ),
          ),
          IconButton(
            tooltip: 'Delete meal',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}