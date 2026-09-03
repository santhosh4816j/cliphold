/// Category of a clip or snippet. Detected automatically but user-overridable.
enum ClipCategory { text, link, code }

extension ClipCategoryX on ClipCategory {
  String get label {
    switch (this) {
      case ClipCategory.text:
        return 'Text';
      case ClipCategory.link:
        return 'Links';
      case ClipCategory.code:
        return 'Code';
    }
  }

  String get dbValue => name;

  static ClipCategory fromDb(String value) {
    return ClipCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClipCategory.text,
    );
  }
}

/// How long unpinned clips are retained before automatic cleanup.
enum RetentionPolicy { never, oneDay, sevenDays, thirtyDays, ninetyDays }

extension RetentionPolicyX on RetentionPolicy {
  String get label {
    switch (this) {
      case RetentionPolicy.never:
        return 'Never delete';
      case RetentionPolicy.oneDay:
        return '1 day';
      case RetentionPolicy.sevenDays:
        return '7 days';
      case RetentionPolicy.thirtyDays:
        return '30 days';
      case RetentionPolicy.ninetyDays:
        return '90 days';
    }
  }

  /// Returns null if clips should never expire.
  Duration? get duration {
    switch (this) {
      case RetentionPolicy.never:
        return null;
      case RetentionPolicy.oneDay:
        return const Duration(days: 1);
      case RetentionPolicy.sevenDays:
        return const Duration(days: 7);
      case RetentionPolicy.thirtyDays:
        return const Duration(days: 30);
      case RetentionPolicy.ninetyDays:
        return const Duration(days: 90);
    }
  }

  String get dbValue => name;

  static RetentionPolicy fromDb(String value) {
    return RetentionPolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RetentionPolicy.sevenDays,
    );
  }
}
