import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/meal_api_model.dart';
import '../../models/meal_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_api_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../discover/meal_detail_screen.dart';
import '../planner/generate_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MealApiModel? _recommendedMeal;
  bool _isLoadingRecommendation = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendedMeal();
  }

  Future<void> _loadRecommendedMeal() async {
    setState(() {
      _isLoadingRecommendation = true;
    });

    final meal = await context.read<MealApiProvider>().getRandomMeal();

    if (!mounted) return;

    setState(() {
      _recommendedMeal = meal;
      _isLoadingRecommendation = false;
    });
  }

  String _getFirstName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'there';
    }

    return name.trim().split(' ').first;
  }

  MealPlanDayModel? _getTodayPlan(MealPlanModel? plan) {
    if (plan == null || plan.days.isEmpty) return null;

    final now = DateTime.now();

    for (final day in plan.days) {
      final sameYear = day.date.year == now.year;
      final sameMonth = day.date.month == now.month;
      final sameDay = day.date.day == now.day;

      if (sameYear && sameMonth && sameDay) {
        return day;
      }
    }

    return plan.days.first;
  }

  void _openGeneratePlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GeneratePlanScreen(),
      ),
    );
  }

  void _openMealDetails(String mealId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(mealId: mealId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    final appUser = authProvider.appUser;
    final userId = firebaseUser?.uid;

    final displayName = appUser?.name ?? firebaseUser?.displayName;
    final firstName = _getFirstName(displayName);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Hello, $firstName 👋',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'What would you like to eat today?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 28),
            if (userId == null)
              const _TodayPlanCard(day: null)
            else
              StreamBuilder<MealPlanModel?>(
                stream: context.read<MealPlanProvider>().getMealPlanStream(
                  userId,
                ),
                builder: (context, snapshot) {
                  final todayPlan = _getTodayPlan(snapshot.data);

                  return _TodayPlanCard(
                    day: todayPlan,
                    onGenerateTap: _openGeneratePlan,
                  );
                },
              ),
            const SizedBox(height: 30),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.calendar_month_outlined,
                    label: 'Generate',
                    onTap: _openGeneratePlan,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.search_outlined,
                    label: 'Discover',
                    onTap: () => widget.onNavigate?.call(1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.favorite_border,
                    label: 'Favorites',
                    onTap: () => widget.onNavigate?.call(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Recommended Meal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _RecommendedMealCard(
              meal: _recommendedMeal,
              isLoading: _isLoadingRecommendation,
              onRefresh: _loadRecommendedMeal,
              onTap: _recommendedMeal == null
                  ? null
                  : () => _openMealDetails(_recommendedMeal!.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final MealPlanDayModel? day;
  final VoidCallback? onGenerateTap;

  const _TodayPlanCard({
    required this.day,
    this.onGenerateTap,
  });

  @override
  Widget build(BuildContext context) {
    final breakfast = day?.meals['Breakfast']?.mealName ?? 'No plan yet';
    final lunch = day?.meals['Lunch']?.mealName ?? 'No plan yet';
    final dinner = day?.meals['Dinner']?.mealName ?? 'No plan yet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s Meal Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Breakfast: $breakfast',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Lunch: $lunch',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Dinner: $dinner',
            style: const TextStyle(color: Colors.white),
          ),
          if (day == null && onGenerateTap != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: onGenerateTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Generate Plan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedMealCard extends StatelessWidget {
  final MealApiModel? meal;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback? onTap;

  const _RecommendedMealCard({
    required this.meal,
    required this.isLoading,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
        ),
      );
    }

    if (meal == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              'Unable to load recommendation.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: onRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  imageUrl: meal!.imageUrl,
                  height: 88,
                  width: 88,
                  fit: BoxFit.cover,
                  placeholder: (context, url) {
                    return Container(
                      height: 88,
                      width: 88,
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
                      height: 88,
                      width: 88,
                      color: AppColors.lightOrange,
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.accentOrange,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal!.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal!.category ?? 'Meal',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}