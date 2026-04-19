import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_category_model.dart';
import '../data/repositories/user_categories_repository.dart';

// ── All categories ──────────────────────────────────────────────

final userCategoriesProvider =
    AsyncNotifierProvider<UserCategoriesNotifier, List<UserCategory>>(
  UserCategoriesNotifier.new,
);

class UserCategoriesNotifier extends AsyncNotifier<List<UserCategory>> {
  @override
  Future<List<UserCategory>> build() =>
      UserCategoriesRepository.instance.getCategories();

  Future<void> add(UserCategory cat) async {
    final saved = await UserCategoriesRepository.instance.upsertCategory(cat);
    state = AsyncData([...state.value!, saved]);
  }

  Future<void> upsert(UserCategory cat) async {
    final saved = await UserCategoriesRepository.instance.upsertCategory(cat);
    state = AsyncData(
        state.value!.map((c) => c.id == saved.id ? saved : c).toList());
  }

  Future<void> delete(String id) async {
    await UserCategoriesRepository.instance.deleteCategory(id);
    state = AsyncData(state.value!.where((c) => c.id != id).toList());
  }
}

// ── Filtered views ──────────────────────────────────────────────

final scheduleCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  final custom = cats.where((c) => c.engine == 'schedule').toList();
  return custom.isNotEmpty ? custom : kDefaultScheduleCategories;
});

final txCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  final custom = cats.where((c) => c.engine == 'transaction').toList();
  return custom.isNotEmpty ? custom : kDefaultTxCategories;
});
