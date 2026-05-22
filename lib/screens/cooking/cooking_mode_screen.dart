import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/ingredient_checklist_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/ingredient_checklist_model.dart';
import '../../models/meal_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cooking_timer_provider.dart';
import '../../providers/ingredient_checklist_provider.dart';

class CookingModeScreen extends StatelessWidget {
  final MealApiModel meal;

  const CookingModeScreen({
    super.key,
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
        .toList();

    if (lineSteps.length > 1) {
      return lineSteps;
    }

    final sentenceSteps = normalizedInstructions
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map(cleanStepLabel)
        .where((step) => step.isNotEmpty)
        .toList();

    if (sentenceSteps.isEmpty) {
      return ['No cooking instructions available.'];
    }

    return sentenceSteps;
  }

  void _showCreateLinkedTimerSheet(BuildContext context) {
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
        return _LinkedTimerFormSheet(
          userId: userId,
          meal: meal,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getInstructionSteps();
    final userId = context.watch<AppAuthProvider>().firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooking Mode'),
        actions: [
          IconButton(
            tooltip: 'Add linked timer',
            onPressed: () => _showCreateLinkedTimerSheet(context),
            icon: const Icon(Icons.timer_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            _CookingHeader(meal: meal),
            const SizedBox(height: 24),
            IngredientChecklistWidget(
              userId: userId,
              meal: meal,
              compact: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cooking Steps',
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
                    onPressed: () => _showCreateLinkedTimerSheet(context),
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('Timer'),
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
            ...List.generate(steps.length, (index) {
              return _CookingStepCard(
                stepNumber: index + 1,
                instruction: steps[index],
                onAddTimer: () => _showCreateLinkedTimerSheet(context),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CookingHeader extends StatelessWidget {
  final MealApiModel meal;

  const _CookingHeader({
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
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  height: 180,
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
                  height: 180,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (meal.category != null)
                      _SmallChip(
                        label: meal.category!,
                        icon: Icons.category_outlined,
                        color: AppColors.primaryGreen,
                      ),
                    if (meal.area != null)
                      _SmallChip(
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

class _CookingProgressCard extends StatelessWidget {
  final String? userId;
  final MealApiModel meal;

  const _CookingProgressCard({
    required this.userId,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const _ProgressContent(
        checkedCount: 0,
        totalCount: 0,
        progress: 0,
      );
    }

    return StreamBuilder<IngredientChecklistModel>(
      stream: context.read<IngredientChecklistProvider>().getChecklistStream(
        userId: userId!,
        mealId: meal.id,
      ),
      builder: (context, snapshot) {
        final checklist = snapshot.data ??
            IngredientChecklistModel.empty(
              userId: userId!,
              mealId: meal.id,
            );

        final checkedSet = checklist.checkedIngredients.toSet();
        final total = meal.ingredients.length;
        final checkedCount = meal.ingredients
            .where((ingredient) => checkedSet.contains(ingredient.name))
            .length;

        return _ProgressContent(
          checkedCount: checkedCount,
          totalCount: total,
          progress: total == 0 ? 0 : checkedCount / total,
        );
      },
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final int checkedCount;
  final int totalCount;
  final double progress;

  const _ProgressContent({
    required this.checkedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preparation Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$checkedCount of $totalCount ingredients checked',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CookingStepCard extends StatelessWidget {
  final int stepNumber;
  final String instruction;
  final VoidCallback onAddTimer;

  const _CookingStepCard({
    required this.stepNumber,
    required this.instruction,
    required this.onAddTimer,
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
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add timer for this step',
            onPressed: onAddTimer,
            icon: const Icon(
              Icons.timer_outlined,
              color: AppColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedTimerFormSheet extends StatefulWidget {
  final String userId;
  final MealApiModel meal;

  const _LinkedTimerFormSheet({
    required this.userId,
    required this.meal,
  });

  @override
  State<_LinkedTimerFormSheet> createState() => _LinkedTimerFormSheetState();
}

class _LinkedTimerFormSheetState extends State<_LinkedTimerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Duration _selectedDuration = const Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Timer for ${widget.meal.name}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hourText = hours.toString().padLeft(2, '0');
    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');

    return '$hourText:$minuteText:$secondText';
  }

  Future<void> _showDurationPicker() async {
    Duration tempDuration = _selectedDuration;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height: 340,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    const Text(
                      'Set Duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        if (tempDuration.inSeconds <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least 1 second.',
                              ),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _selectedDuration = tempDuration;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: _selectedDuration,
                  onTimerDurationChanged: (duration) {
                    tempDuration = duration;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveLinkedTimer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDuration.inSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 second.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final provider = context.read<CookingTimerProvider>();

    final success = await provider.createTimer(
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: _selectedDuration.inSeconds,
      linkedMealId: widget.meal.id,
      linkedMealName: widget.meal.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Linked timer saved.'
              : provider.errorMessage ?? 'Unable to save linked timer.',
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
    final provider = context.watch<CookingTimerProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Linked Timer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.meal.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _titleController,
                labelText: 'Timer Title',
                prefixIcon: Icons.timer_outlined,
                validator: (value) {
                  return Validators.requiredField(value, 'timer title');
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showDurationPicker,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.borderGray,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textGray,
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(_selectedDuration),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description or Cooking Step',
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Linked Timer',
                isLoading: provider.isLoading,
                onPressed: _saveLinkedTimer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SmallChip({
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