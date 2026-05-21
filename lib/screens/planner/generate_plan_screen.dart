import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_plan_provider.dart';

class GeneratePlanScreen extends StatefulWidget {
  const GeneratePlanScreen({super.key});

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  DateTime _weekStartDate = DateTime.now();
  int _numberOfDays = 7;
  String _selectedCategory = 'Random';

  final Map<String, bool> _selectedSlots = {
    'Breakfast': true,
    'Lunch': true,
    'Dinner': true,
  };

  final List<int> _dayOptions = [3, 5, 7];

  final List<String> _categories = const [
    'Random',
    'Chicken',
    'Beef',
    'Seafood',
    'Vegetarian',
    'Dessert',
    'Pasta',
  ];

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _pickWeekStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _weekStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      _weekStartDate = pickedDate;
    });
  }

  Future<void> _generatePlan() async {
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

    final selectedMealSlots = _selectedSlots.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedMealSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one meal slot.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final success = await context.read<MealPlanProvider>().generateMealPlan(
      userId: userId,
      weekStartDate: _weekStartDate,
      numberOfDays: _numberOfDays,
      category: _selectedCategory,
      selectedSlots: selectedMealSlots,
    );

    if (!mounted) return;

    final provider = context.read<MealPlanProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Meal plan generated successfully.'
              : provider.errorMessage ?? 'Unable to generate meal plan.',
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
    final mealPlanProvider = context.watch<MealPlanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Meal Plan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your preferences',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MealMate will generate your weekly meal plan using TheMealDB meals.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Week Start Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickWeekStartDate,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_weekStartDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Number of Days',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _dayOptions.map((days) {
                    final isSelected = days == _numberOfDays;

                    return ChoiceChip(
                      label: Text('$days Days'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryGreen,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _numberOfDays = days;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Preferred Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Meal Slots',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                ..._selectedSlots.keys.map((slot) {
                  return CheckboxListTile(
                    value: _selectedSlots[slot],
                    activeColor: AppColors.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      slot,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedSlots[slot] = value ?? false;
                      });
                    },
                  );
                }),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Generate Meal Plan',
                  isLoading: mealPlanProvider.isLoading,
                  onPressed: _generatePlan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}