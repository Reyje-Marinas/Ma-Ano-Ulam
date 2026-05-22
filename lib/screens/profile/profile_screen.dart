import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cooking_timer_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/meal_plan_provider.dart';

class ProfileScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const ProfileScreen({
    super.key,
    this.onNavigate,
  });

  String _getInitial(String? nameOrEmail) {
    if (nameOrEmail == null || nameOrEmail.trim().isEmpty) {
      return 'M';
    }

    return nameOrEmail.trim()[0].toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) return;

    await context.read<AppAuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  void _showEditProfileSheet(BuildContext context, String currentName) {
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
        return _EditProfileSheet(currentName: currentName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    final appUser = authProvider.appUser;

    final name = appUser?.name ?? firebaseUser?.displayName ?? 'Ma! Ano Ulam User';
    final email = appUser?.email ?? firebaseUser?.email ?? 'No email';
    final userId = firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.lightGreen,
                child: Text(
                  _getInitial(name),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 30),
              if (userId != null) _StatsSection(userId: userId),
              const SizedBox(height: 30),
              _ProfileOption(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () => _showEditProfileSheet(context, name),
              ),
              const SizedBox(height: 14),
              _ProfileOption(
                icon: Icons.favorite_border,
                title: 'Saved Meals',
                onTap: () {
                  onNavigate?.call(3);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 14),
              _ProfileOption(
                icon: Icons.info_outline,
                title: 'About Ma! Ano Ulam?',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Ma! Ano Ulam?',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Text(
                      '🍲',
                      style: TextStyle(fontSize: 32),
                    ),
                    children: const [
                      Text(
                        'Ma! Ano Ulam? helps users discover recipes, save meals, track ingredients, create cooking timers, and organize weekly meal plans.',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _ProfileOption(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: AppColors.errorRed,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String userId;

  const _StatsSection({
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: context.read<FavoriteProvider>().getFavoritesCount(userId),
            builder: (context, snapshot) {
              return _StatCard(
                value: snapshot.data?.toString() ?? '0',
                label: 'Saved',
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FutureBuilder<int>(
            future: context.read<MealPlanProvider>().getMealPlanCount(userId),
            builder: (context, snapshot) {
              return _StatCard(
                value: snapshot.data?.toString() ?? '0',
                label: 'Plans',
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FutureBuilder<int>(
            future: context.read<CookingTimerProvider>().getTimerCount(userId),
            builder: (context, snapshot) {
              return _StatCard(
                value: snapshot.data?.toString() ?? '0',
                label: 'Timers',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = AppColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textGray,
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String currentName;

  const _EditProfileSheet({
    required this.currentName,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AppAuthProvider>();

    final success = await authProvider.updateName(_nameController.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile updated successfully.'
              : authProvider.errorMessage ?? 'Unable to update profile.',
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
    final authProvider = context.watch<AppAuthProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                return Validators.requiredField(value, 'full name');
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Save Changes',
              isLoading: authProvider.isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}