import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_legacy_repository.dart';
import '../../domain/legacy_profile.dart';
import '../../domain/legacy_repository.dart';

final legacyRepositoryProvider = Provider<LegacyRepository>((ref) => SupabaseLegacyRepository());

final legacyProfileProvider = FutureProvider.autoDispose<LegacyProfile>((ref) {
  return ref.watch(legacyRepositoryProvider).load();
});

final legacyAlignmentProvider = FutureProvider.autoDispose<String>((ref) {
  return ref.watch(legacyRepositoryProvider).checkAlignment();
});
