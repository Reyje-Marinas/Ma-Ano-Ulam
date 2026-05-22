import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/meal_api_model.dart';
import '../constants/app_colors.dart';

class MealCard extends StatelessWidget {
  final MealApiModel meal;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderGray.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: meal.imageUrl,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  width: 104,
                  height: 104,
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
                  width: 104,
                  height: 104,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 104,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    width: 140,
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),
          IconButton(
            onPressed: onFavoriteTap,
            icon: const Icon(
              Icons.favorite_border,
              color: AppColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }
}