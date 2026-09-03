import 'enums.dart';

/// A user-authored reusable snippet (as opposed to a captured clip).
class Snippet {
  final String id;
  final String name;
  final String content;
  final ClipCategory category;
  final String? shortcut;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;

  const Snippet({
    required this.id,
    required this.name,
    required this.content,
    required this.category,
    this.shortcut,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  Snippet copyWith({
    String? name,
    String? content,
    ClipCategory? category,
    String? shortcut,
    bool clearShortcut = false,
    DateTime? updatedAt,
    bool? pinned,
  }) {
    return Snippet(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      category: category ?? this.category,
      shortcut: clearShortcut ? null : (shortcut ?? this.shortcut),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'category': category.dbValue,
      'shortcut': shortcut,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'pinned': pinned ? 1 : 0,
    };
  }

  factory Snippet.fromMap(Map<String, Object?> map) {
    return Snippet(
      id: map['id'] as String,
      name: map['name'] as String,
      content: map['content'] as String,
      category: ClipCategoryX.fromDb(map['category'] as String),
      shortcut: map['shortcut'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      pinned: (map['pinned'] as int) == 1,
    );
  }
}
