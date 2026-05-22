import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/cooking_timer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cooking_timer_provider.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key});

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  Stream<List<CookingTimerModel>>? _timersStream;
  String? _cachedUserId;

  void _prepareStream(BuildContext context, String userId) {
    if (_cachedUserId == userId && _timersStream != null) return;

    _cachedUserId = userId;
    _timersStream = context.read<CookingTimerProvider>().getUserTimersStream(
      userId,
    );
  }

  void _showCreateTimerSheet(BuildContext context) {
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
        return const _TimerFormSheet();
      },
    );
  }

  void _showEditTimerSheet(
      BuildContext context,
      CookingTimerModel timer,
      ) {
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
        return _TimerFormSheet(timer: timer);
      },
    );
  }

  Future<void> _deleteTimer(
      BuildContext context,
      CookingTimerModel timer,
      ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Timer'),
          content: Text('Delete "${timer.title}"?'),
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

    final provider = context.read<CookingTimerProvider>();

    final success = await provider.deleteTimer(timer.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Timer deleted.'
              : provider.errorMessage ?? 'Unable to delete timer.',
        ),
        backgroundColor:
        success ? AppColors.primaryGreen : AppColors.errorRed,
      ),
    );
  }

  void _showCompletedTimerAlert(BuildContext context) {
    final completedTitle =
    context.read<CookingTimerProvider>().consumeCompletedTimerTitle();

    if (completedTitle == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$completedTitle timer is complete!'),
        backgroundColor: AppColors.primaryGreen,
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
          subtitle: 'Please login to view your cooking timers.',
        ),
      );
    }

    _prepareStream(context, userId);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooking Timers',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Run multiple reusable timers.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTimerSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CookingTimerModel>>(
              stream: _timersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LoadingWidget(
                    message: 'Loading cooking timers...',
                  );
                }

                if (snapshot.hasError) {
                  return const EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'Unable to load timers',
                    subtitle: 'Please check your connection and try again.',
                  );
                }

                final timers = snapshot.data ?? [];

                if (timers.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.timer_outlined,
                    title: 'No timers yet',
                    subtitle:
                    'Create reusable cooking timers for boiling, frying, baking, and more.',
                    buttonText: 'Create Timer',
                    onButtonPressed: () => _showCreateTimerSheet(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  itemCount: timers.length,
                  itemBuilder: (context, index) {
                    final timer = timers[index];

                    return Consumer<CookingTimerProvider>(
                      builder: (context, timerProvider, _) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showCompletedTimerAlert(context);
                        });

                        return _CookingTimerCard(
                          timer: timer,
                          formattedTime: timerProvider.formatSeconds(
                            timerProvider.getRemainingSeconds(timer),
                          ),
                          isRunning: timerProvider.isRunning(timer.id),
                          isCompleted: timerProvider.isCompleted(timer.id),
                          onStart: () => timerProvider.startTimer(timer),
                          onPause: () => timerProvider.pauseTimer(timer.id),
                          onReset: () => timerProvider.resetTimer(timer),
                          onEdit: () => _showEditTimerSheet(context, timer),
                          onDelete: () => _deleteTimer(context, timer),
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
}

class _CookingTimerCard extends StatelessWidget {
  final CookingTimerModel timer;
  final String formattedTime;
  final bool isRunning;
  final bool isCompleted;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CookingTimerCard({
    required this.timer,
    required this.formattedTime,
    required this.isRunning,
    required this.isCompleted,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isCompleted
        ? AppColors.accentOrange
        : isRunning
        ? AppColors.primaryGreen
        : AppColors.textGray;

    final statusText = isCompleted
        ? 'Completed'
        : isRunning
        ? 'Running'
        : 'Ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isRunning ? AppColors.lightGreen : Colors.white,
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
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.timer_outlined,
                  color: statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timer.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timer.description.isEmpty
                          ? 'Reusable cooking timer'
                          : timer.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (timer.linkedMealName != null &&
              timer.linkedMealName!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Linked recipe: ${timer.linkedMealName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentOrange,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isRunning ? onPause : onStart,
                  icon: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(isRunning ? 'Pause' : 'Start'),
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
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Reset',
                onPressed: onReset,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.primaryGreen,
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textGray,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerFormSheet extends StatefulWidget {
  final CookingTimerModel? timer;

  const _TimerFormSheet({
    this.timer,
  });

  @override
  State<_TimerFormSheet> createState() => _TimerFormSheetState();
}

class _TimerFormSheetState extends State<_TimerFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkedRecipeController = TextEditingController();

  Duration _selectedDuration = const Duration(minutes: 1);

  bool get _isEditing => widget.timer != null;

  @override
  void initState() {
    super.initState();

    final timer = widget.timer;

    if (timer != null) {
      _titleController.text = timer.title;
      _descriptionController.text = timer.description;
      _linkedRecipeController.text = timer.linkedMealName ?? '';
      _selectedDuration = Duration(seconds: timer.durationSeconds);
    }
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
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

  Future<void> _saveTimer() async {
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

    final userId = context.read<AppAuthProvider>().firebaseUser?.uid;

    if (userId == null) {
      Navigator.pop(context);
      return;
    }

    final provider = context.read<CookingTimerProvider>();
    final linkedRecipeName = _linkedRecipeController.text.trim();

    bool success;

    if (_isEditing) {
      final updatedTimer = widget.timer!.copyWith(
        title: _titleController.text.trim(),
        durationSeconds: _selectedDuration.inSeconds,
        description: _descriptionController.text.trim(),
        linkedMealName: linkedRecipeName.isEmpty ? null : linkedRecipeName,
        updatedAt: DateTime.now(),
      );

      success = await provider.updateTimer(updatedTimer);
    } else {
      success = await provider.createTimer(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        durationSeconds: _selectedDuration.inSeconds,
        linkedMealName: linkedRecipeName.isEmpty ? null : linkedRecipeName,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? _isEditing
              ? 'Timer updated.'
              : 'Timer created.'
              : provider.errorMessage ?? 'Unable to save timer.',
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
              Text(
                _isEditing ? 'Edit Timer' : 'Create Timer',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
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
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Format: hours : minutes : seconds',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description or Cooking Step',
                prefixIcon: Icons.notes_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _linkedRecipeController,
                labelText: 'Linked Recipe Name Optional',
                prefixIcon: Icons.restaurant_menu_outlined,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isEditing ? 'Save Changes' : 'Save Timer',
                isLoading: provider.isLoading,
                onPressed: _saveTimer,
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
    _linkedRecipeController.dispose();
    super.dispose();
  }
}