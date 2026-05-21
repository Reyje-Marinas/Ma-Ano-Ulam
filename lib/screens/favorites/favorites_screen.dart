import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/favorite_meal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../discover/meal_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _removeFavorite(
      BuildContext context,
      FavoriteMealModel favorite,
      ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Favorite'),
          content: Text(
            'Remove ${favorite.mealName} from your favorites?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !context.mounted) return;

    final success = await context
        .read<FavoriteProvider>()
        .removeFavorite(favorite.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Removed from favorites.'
              : context.read<FavoriteProvider>().errorMessage ??
              'Unable to remove favorite.',
        ),
        backgroundColor: success ? AppColors.primaryGreen : AppColors.errorRed,
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
          subtitle: 'Please login to view your favorite meals.',
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorites',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your saved meals',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FavoriteMealModel>>(
              stream: context
                  .read<FavoriteProvider>()
                  .getFavoritesStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(
                    message: 'Loading favorites...',
                  );
                }

                if (snapshot.hasError) {
                  return const EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'Unable to load favorites',
                    subtitle: 'Please check your connection and try again.',
                  );
                }

                final favorites = snapshot.data ?? [];

                if (favorites.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.favorite_border,
                    title: 'No favorites yet',
                    subtitle:
                    'Discover meals and save your favorite recipes here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = favorites[index];

                    return _FavoriteMealCard(
                      favorite: favorite,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return MealDetailScreen(
                                mealId: favorite.mealId,
                              );
                            },
                          ),
                        );
                      },
                      onRemove: () => _removeFavorite(context, favorite),
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

class _FavoriteMealCard extends StatelessWidget {
  final FavoriteMealModel favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteMealCard({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: favorite.imageUrl,
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
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.mealName,
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
                      favorite.category ?? 'Meal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                    const Spacer(),
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
            ),
          ),
          IconButton(
            onPressed: onRemove,
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