import 'package:equatable/equatable.dart';

class Idea extends Equatable {
  const Idea({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String status; // 'backlog' | 'thinking' | 'active' | 'done'
  final List<String> tags;
  final DateTime createdAt;

  factory Idea.fromJson(Map<String, dynamic> json) => Idea(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'backlog',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
      };

  Idea copyWith({
    String? title,
    String? description,
    String? status,
    List<String>? tags,
  }) =>
      Idea(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        tags: tags ?? this.tags,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, status, createdAt];
}
