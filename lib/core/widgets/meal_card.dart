import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/meal_api_model.dart';
import '../constants/app_colors.dart';

class MealCard extends StatelessWidget {
  final MealApiModel meal;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavoriteButton;

  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.onFavoriteTap,
    this.showFavoriteButton = true,
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
              imageUrl: meal.imageUrl,
              height: 96,
              width: 96,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  height: 96,
                  width: 96,
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
                  height: 96,
                  width: 96,
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
            child: SizedBox(
              height: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
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
                    meal.category ?? 'Meal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(
                          color: AppColors.primaryGreen,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showFavoriteButton) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: onFavoriteTap,
              icon: const Icon(
                Icons.favorite_border,
                color: AppColors.accentOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}