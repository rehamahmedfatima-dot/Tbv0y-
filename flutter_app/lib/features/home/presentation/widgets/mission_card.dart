import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MissionCard extends StatelessWidget {
  final String title;
  final bool completed;
  final VoidCallback onComplete;

  const MissionCard({super.key, required this.title, required this.completed, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.accentGradient),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Mission",
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: completed ? null : onComplete,
            icon: Icon(
              completed ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
