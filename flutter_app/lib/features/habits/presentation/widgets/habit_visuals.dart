import 'package:flutter/material.dart';

/// Central place mapping the string icon/color keys stored in Supabase to
/// actual Flutter values, so habit cards and the create/edit form always
/// render identically.
class HabitVisuals {
  HabitVisuals._();

  static const Map<String, IconData> iconMap = {
    'favorite': Icons.favorite_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'menu_book': Icons.menu_book_rounded,
    'school': Icons.school_rounded,
    'work': Icons.work_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'spa': Icons.spa_rounded,
    'savings': Icons.savings_rounded,
    'people': Icons.people_rounded,
    'star': Icons.star_rounded,
    'water_drop': Icons.water_drop_rounded,
    'directions_walk': Icons.directions_walk_rounded,
    'nightlight': Icons.nightlight_round,
    'edit_note': Icons.edit_note_rounded,
    'restaurant': Icons.restaurant_rounded,
  };

  static const List<String> selectableIcons = [
    'favorite', 'fitness_center', 'menu_book', 'school', 'work',
    'self_improvement', 'spa', 'savings', 'people', 'star',
    'water_drop', 'directions_walk', 'nightlight', 'edit_note', 'restaurant',
  ];

  static const List<String> selectableColors = [
    '#2563EB', '#14B8A6', '#F59E0B', '#22C55E', '#F97316',
    '#EF4444', '#8B5CF6', '#EC4899', '#0EA5E9', '#64748B',
  ];

  static IconData iconFor(String key) => iconMap[key] ?? Icons.star_rounded;

  static Color colorFrom(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
