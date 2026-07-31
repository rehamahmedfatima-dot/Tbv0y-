import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class GrowthTreeCard extends StatelessWidget {
  final int stage; // 1-4: seed, sapling, tree, blooming
  final double health; // 0-100
  final String season;

  const GrowthTreeCard({super.key, required this.stage, required this.health, required this.season});

  IconData get _treeIcon {
    switch (stage) {
      case 1:
        return Icons.grass_rounded;
      case 2:
        return Icons.park_outlined;
      case 3:
        return Icons.park_rounded;
      default:
        return Icons.forest_rounded;
    }
  }

  String get _stageLabel {
    switch (stage) {
      case 1:
        return 'Seed';
      case 2:
        return 'Sapling';
      case 3:
        return 'Growing Tree';
      default:
        return 'Blooming Tree';
    }
  }

  List<Color> get _seasonGradient {
    switch (season) {
      case 'summer':
        return [const Color(0xFF22C55E), const Color(0xFF14B8A6)];
      case 'autumn':
        return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
      case 'winter':
        return [const Color(0xFF64748B), const Color(0xFF94A3B8)];
      default:
        return AppColors.primaryGradient; // spring
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _seasonGradient.map((c) => c.withValues(alpha: 0.12)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: _seasonGradient.first.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _seasonGradient),
              shape: BoxShape.circle,
            ),
            child: Icon(_treeIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_stageLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Health ${health.round()}% • ${season[0].toUpperCase()}${season.substring(1)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: (health / 100).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(_seasonGradient.first),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
