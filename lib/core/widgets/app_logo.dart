import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showCircleBackground;

  const AppLogo({
    super.key,
    this.size = 150,
    this.showCircleBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/ma_ano_ulam_logo_transparent.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!showCircleBackground) {
      return logo;
    }

    return Container(
      width: size + 22,
      height: size + 22,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.lightGreen,
          width: 2,
        ),
      ),
      child: logo,
    );
  }
}