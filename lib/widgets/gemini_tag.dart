import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// Gemini AI badge tag.
class GeminiTag extends StatelessWidget {
  const GeminiTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.geminiPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(
          color: AppColors.geminiPurple.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        '✦ Gemini',
        style: AppTextStyles.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.geminiPurple,
        ),
      ),
    );
  }
}
