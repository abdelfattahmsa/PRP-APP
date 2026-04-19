import '../../../../services/supabase_service.dart';
import '../models/user_category_model.dart';

class UserCategoriesRepository {
  UserCategoriesRepository._();
  static final instance = UserCategoriesRepository._();

  final _service = SupabaseService.instance;

  Future<List<UserCategory>> getCategories() =>
      _service.getUserCategories();
  Future<UserCategory> upsertCategory(UserCategory cat) =>
      _service.upsertUserCategory(cat);
  Future<void> deleteCategory(String id) =>
      _service.deleteUserCategory(id);
}
