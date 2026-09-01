/// Helpers for Google Sheets A1-notation column letters (A..Z, AA, AB, ...).
class SheetColumns {
  SheetColumns._();

  /// Google Sheets caps out at 18,278 columns (ZZZ); three letters is plenty.
  static const int maxLetters = 3;

  /// "A" -> 0, "Z" -> 25, "AA" -> 26. Returns null if [letter] isn't a
  /// valid column reference.
  static int? letterToIndex(String letter) {
    final normalized = letter.trim().toUpperCase();
    if (normalized.isEmpty || normalized.length > maxLetters) return null;
    var index = 0;
    for (final codeUnit in normalized.codeUnits) {
      if (codeUnit < 65 || codeUnit > 90) return null; // not A-Z
      index = index * 26 + (codeUnit - 64);
    }
    return index - 1;
  }

  /// 0 -> "A", 25 -> "Z", 26 -> "AA".
  static String indexToLetter(int index) {
    if (index < 0) return 'A';
    var remaining = index + 1;
    final buffer = StringBuffer();
    while (remaining > 0) {
      final rem = (remaining - 1) % 26;
      buffer.write(String.fromCharCode(65 + rem));
      remaining = (remaining - 1) ~/ 26;
    }
    return String.fromCharCodes(buffer.toString().codeUnits.reversed);
  }

  static bool isValid(String letter) => letterToIndex(letter) != null;

  /// Normalizes user input ("  b " -> "B"), or null if invalid.
  static String? normalize(String letter) {
    final index = letterToIndex(letter);
    return index == null ? null : indexToLetter(index);
  }

  /// Highest column letter used by [columnLetters] - defines how wide a
  /// written row / read range needs to be.
  static String maxLetterOf(Map<String, String> columnLetters) {
    var maxIndex = 0;
    for (final letter in columnLetters.values) {
      final index = letterToIndex(letter);
      if (index != null && index > maxIndex) maxIndex = index;
    }
    return indexToLetter(maxIndex);
  }

  /// Places each field's value at its mapped column, padding the gaps with
  /// empty strings so Sheets keeps the alignment. Fields whose letter is
  /// missing or invalid are skipped.
  static List<Object?> buildRow({
    required Map<String, Object?> valuesByField,
    required Map<String, String> columnLetters,
  }) {
    final placed = <int, Object?>{};
    var maxIndex = 0;
    for (final entry in valuesByField.entries) {
      final letter = columnLetters[entry.key];
      if (letter == null) continue;
      final index = letterToIndex(letter);
      if (index == null) continue;
      placed[index] = entry.value;
      if (index > maxIndex) maxIndex = index;
    }
    return List<Object?>.generate(maxIndex + 1, (i) => placed[i] ?? '');
  }

  /// Field keys that share a column letter with another field - these would
  /// overwrite each other, so the UI blocks saving while any exist.
  static Set<String> duplicateFields(Map<String, String> columnLetters) {
    final byLetter = <String, List<String>>{};
    for (final entry in columnLetters.entries) {
      final normalized = normalize(entry.value);
      if (normalized == null) continue;
      byLetter.putIfAbsent(normalized, () => []).add(entry.key);
    }
    return byLetter.values
        .where((fields) => fields.length > 1)
        .expand((fields) => fields)
        .toSet();
  }
}
