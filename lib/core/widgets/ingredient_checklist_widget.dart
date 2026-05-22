import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ingredient_checklist_model.dart';
import '../../models/meal_api_model.dart';
import '../../providers/ingredient_checklist_provider.dart';
import '../constants/app_colors.dart';

class IngredientChecklistWidget extends StatefulWidget {
  final String? userId;
  final MealApiModel meal;
  final bool compact;
  final bool showReset;

  const IngredientChecklistWidget({
    super.key,
    required this.userId,
    required this.meal,
    this.compact = false,
    this.showReset = true,
  });

  @override
  State<IngredientChecklistWidget> createState() =>
      _IngredientChecklistWidgetState();
}

class _IngredientChecklistWidgetState extends State<IngredientChecklistWidget> {
  Set<String> _localCheckedIngredients = {};
  bool _hasLoadedInitialData = false;

  Future<void> _resetChecklist(BuildContext context) async {
    if (widget.userId == null) return;

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

    setState(() {
      _localCheckedIngredients.clear();
    });

    final provider = context.read<IngredientChecklistProvider>();

    final success = await provider.resetChecklist(
      userId: widget.userId!,
      mealId: widget.meal.id,
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

  Future<void> _toggleIngredient({
    required BuildContext context,
    required String ingredientName,
    required bool newValue,
  }) async {
    if (widget.userId == null) return;

    setState(() {
      if (newValue) {
        _localCheckedIngredients.add(ingredientName);
      } else {
        _localCheckedIngredients.remove(ingredientName);
      }
    });

    final provider = context.read<IngredientChecklistProvider>();

    final success = await provider.setIngredientChecked(
      userId: widget.userId!,
      mealId: widget.meal.id,
      ingredientName: ingredientName,
      isChecked: newValue,
    );

    if (!context.mounted || success) return;

    setState(() {
      if (newValue) {
        _localCheckedIngredients.remove(ingredientName);
      } else {
        _localCheckedIngredients.add(ingredientName);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Unable to update checklist.',
        ),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meal.ingredients.isEmpty) {
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

    if (widget.userId == null) {
      return _ChecklistContent(
        meal: widget.meal,
        compact: widget.compact,
        showReset: false,
        checkedIngredients: const {},
        onReset: null,
        onToggle: null,
      );
    }

    return StreamBuilder<IngredientChecklistModel>(
      stream: context.read<IngredientChecklistProvider>().getChecklistStream(
        userId: widget.userId!,
        mealId: widget.meal.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_hasLoadedInitialData) {
          _localCheckedIngredients =
              snapshot.data!.checkedIngredients.toSet();
          _hasLoadedInitialData = true;
        }

        return _ChecklistContent(
          meal: widget.meal,
          compact: widget.compact,
          showReset: widget.showReset,
          checkedIngredients: _localCheckedIngredients,
          onReset: () => _resetChecklist(context),
          onToggle: (ingredientName, newValue) {
            _toggleIngredient(
              context: context,
              ingredientName: ingredientName,
              newValue: newValue,
            );
          },
        );
      },
    );
  }
}

class _ChecklistContent extends StatelessWidget {
  final MealApiModel meal;
  final bool compact;
  final bool showReset;
  final Set<String> checkedIngredients;
  final VoidCallback? onReset;
  final void Function(String ingredientName, bool newValue)? onToggle;

  const _ChecklistContent({
    required this.meal,
    required this.compact,
    required this.showReset,
    required this.checkedIngredients,
    required this.onReset,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final total = meal.ingredients.length;

    final checkedCount = meal.ingredients
        .where((ingredient) => checkedIngredients.contains(ingredient.name))
        .length;

    final progress = total == 0 ? 0.0 : checkedCount / total;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
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
              if (showReset && onReset != null)
                TextButton(
                  onPressed: onReset,
                  child: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            compact
                ? 'Tap ingredients while cooking • $checkedCount of $total checked'
                : '$checkedCount of $total ingredients checked',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...meal.ingredients.map((ingredient) {
            final isChecked = checkedIngredients.contains(ingredient.name);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked ? AppColors.lightGreen : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isChecked
                      ? AppColors.primaryGreen
                      : AppColors.borderGray.withOpacity(0.7),
                ),
              ),
              child: CheckboxListTile(
                value: isChecked,
                activeColor: AppColors.primaryGreen,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                title: Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color:
                    isChecked ? AppColors.darkGreen : AppColors.textDark,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: ingredient.measure.trim().isEmpty
                    ? null
                    : Text(
                  ingredient.measure,
                  style: TextStyle(
                    fontSize: 12,
                    color: isChecked
                        ? AppColors.darkGreen
                        : AppColors.textGray,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                onChanged: onToggle == null
                    ? null
                    : (value) {
                  onToggle!(
                    ingredient.name,
                    value ?? false,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}