import '../../../../services/supabase_service.dart';
import '../models/idea_models.dart';

class IdeasRepository {
  IdeasRepository._();
  static final instance = IdeasRepository._();

  final _service = SupabaseService.instance;

  Future<List<Idea>> getIdeas() => _service.getIdeas();
  Future<Idea> upsertIdea(Idea idea) => _service.upsertIdea(idea);
  Future<void> deleteIdea(String id) => _service.deleteIdea(id);
}
