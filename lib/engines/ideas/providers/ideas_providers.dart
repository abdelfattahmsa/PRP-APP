import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/idea_models.dart';
import '../data/repositories/ideas_repository.dart';

final ideasProvider =
    AsyncNotifierProvider<IdeasNotifier, List<Idea>>(IdeasNotifier.new);

class IdeasNotifier extends AsyncNotifier<List<Idea>> {
  @override
  Future<List<Idea>> build() => IdeasRepository.instance.getIdeas();

  Future<void> add(Idea idea) async {
    final saved = await IdeasRepository.instance.upsertIdea(idea);
    state = AsyncData([saved, ...state.value!]);
  }

  Future<void> upsert(Idea idea) async {
    final saved = await IdeasRepository.instance.upsertIdea(idea);
    state = AsyncData(
        state.value!.map((i) => i.id == saved.id ? saved : i).toList());
  }

  Future<void> delete(String id) async {
    await IdeasRepository.instance.deleteIdea(id);
    state = AsyncData(state.value!.where((i) => i.id != id).toList());
  }

  Future<void> setStatus(String id, String status) async {
    final idea = state.value!.firstWhere((i) => i.id == id);
    await upsert(idea.copyWith(status: status));
  }
}
