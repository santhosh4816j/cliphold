import 'enums.dart';

/// A single clipboard history entry.
class ClipItem {
  final String id;
  final String content;
  final ClipCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;

  /// Simple hash of normalized content, used for fast duplicate detection.
  final String contentHash;

  /// Number of times this exact content has been copied. Incremented
  /// instead of creating duplicate rows.
  final int copyCount;

  const ClipItem({
    required this.id,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.pinned,
    required this.contentHash,
    this.copyCount = 1,
  });

  /// Preview text used in list cards (first line, truncated).
  String get preview {
    final singleLine = content.replaceAll('\n', ' ').trim();
    if (singleLine.length <= 140) return singleLine;
    return '${singleLine.substring(0, 140)}…';
  }

  int get lineCount => '\n'.allMatches(content).length + 1;

  ClipItem copyWith({
    String? content,
    ClipCategory? category,
    DateTime? updatedAt,
    bool? pinned,
    String? contentHash,
    int? copyCount,
  }) {
    return ClipItem(
      id: id,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      contentHash: contentHash ?? this.contentHash,
      copyCount: copyCount ?? this.copyCount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category.dbValue,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'pinned': pinned ? 1 : 0,
      'content_hash': contentHash,
      'copy_count': copyCount,
    };
  }

  factory ClipItem.fromMap(Map<String, Object?> map) {
    return ClipItem(
      id: map['id'] as String,
      content: map['content'] as String,
      category: ClipCategoryX.fromDb(map['category'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      pinned: (map['pinned'] as int) == 1,
      contentHash: map['content_hash'] as String,
      copyCount: (map['copy_count'] as int?) ?? 1,
    );
  }
}
