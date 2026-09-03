import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/enums.dart';

/// Pure, deterministic helpers for classifying and hashing clipboard content.
/// Kept dependency-free of Flutter/DB so it is trivially unit-testable.
class CategoryDetector {
  CategoryDetector._();

  static final RegExp _urlPattern = RegExp(
    r'^(https?:\/\/|www\.)[^\s]+$|^[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}(\/[^\s]*)?$',
    caseSensitive: false,
  );

  static final RegExp _codeSignals = RegExp(
    r'(\bfunction\b|\bclass\b|\bconst\b|\blet\b|\bvar\b|\bimport\b|\bexport\b|'
    r'\bpublic\b|\bprivate\b|\bstatic\b|\breturn\b|\bdef\b|\b#include\b|'
    r'=>|==|!=|&&|\|\||;\s*$|^\s*[{}]\s*$|^\s*(if|for|while)\s*\(|'
    r'<\/?[a-zA-Z][^>]*>|^\s*(SELECT|INSERT|UPDATE|DELETE)\s+.+FROM)',
    multiLine: true,
  );

  /// Guesses a category for a freshly captured clip. Users can always
  /// override this manually afterward.
  static ClipCategory detect(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return ClipCategory.text;

    // Single-line, single-token content that looks like a URL.
    if (!trimmed.contains('\n') &&
        !trimmed.contains(' ') &&
        _urlPattern.hasMatch(trimmed)) {
      return ClipCategory.link;
    }

    final codeMatches = _codeSignals.allMatches(trimmed).length;
    final lineCount = '\n'.allMatches(trimmed).length + 1;
    // Multiple code-like signals, or clear multi-line structure with symbols.
    if (codeMatches >= 2 ||
        (lineCount > 1 &&
            RegExp(r'[{}();]').hasMatch(trimmed) &&
            codeMatches >= 1)) {
      return ClipCategory.code;
    }

    return ClipCategory.text;
  }

  /// Normalizes content for duplicate comparison: trims surrounding
  /// whitespace and collapses trailing newlines so trivial whitespace
  /// differences don't create duplicate history entries.
  static String normalize(String content) => content.trim();

  /// Stable hash used to detect duplicate clipboard captures quickly
  /// without comparing full (potentially large) content strings.
  static String hash(String content) {
    final bytes = utf8.encode(normalize(content));
    return sha256.convert(bytes).toString();
  }
}
