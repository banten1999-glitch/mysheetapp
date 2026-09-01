import 'package:flutter_test/flutter_test.dart';
import 'package:mysheetapp/core/utils/sheet_columns.dart';

void main() {
  group('letterToIndex / indexToLetter', () {
    test('maps single letters', () {
      expect(SheetColumns.letterToIndex('A'), 0);
      expect(SheetColumns.letterToIndex('I'), 8);
      expect(SheetColumns.letterToIndex('Z'), 25);
    });

    test('maps multi-letter columns', () {
      expect(SheetColumns.letterToIndex('AA'), 26);
      expect(SheetColumns.letterToIndex('AB'), 27);
      expect(SheetColumns.letterToIndex('BA'), 52);
    });

    test('is case- and whitespace-tolerant', () {
      expect(SheetColumns.letterToIndex(' b '), 1);
      expect(SheetColumns.normalize(' aa '), 'AA');
    });

    test('rejects invalid input', () {
      expect(SheetColumns.letterToIndex(''), isNull);
      expect(SheetColumns.letterToIndex('A1'), isNull);
      expect(SheetColumns.letterToIndex('!'), isNull);
      expect(SheetColumns.letterToIndex('ABCD'), isNull);
      expect(SheetColumns.isValid('AA'), isTrue);
    });

    test('round-trips', () {
      for (final index in [0, 5, 25, 26, 51, 52, 700]) {
        final letter = SheetColumns.indexToLetter(index);
        expect(SheetColumns.letterToIndex(letter), index, reason: letter);
      }
    });
  });

  group('buildRow', () {
    test('places values at their mapped columns, padding gaps', () {
      final row = SheetColumns.buildRow(
        valuesByField: {'serial': 7, 'statement': 'إيجار'},
        columnLetters: {'serial': 'A', 'statement': 'C'},
      );
      expect(row, [7, '', 'إيجار']);
    });

    test('honours a remapped layout', () {
      // serial moved to B, date to F - matches the user-facing example.
      final row = SheetColumns.buildRow(
        valuesByField: {'serial': 101, 'date': '2026-09-01'},
        columnLetters: {'serial': 'B', 'date': 'F'},
      );
      expect(row.length, 6);
      expect(row[1], 101);
      expect(row[5], '2026-09-01');
      expect(row[0], '');
    });

    test('supports two-letter columns', () {
      final row = SheetColumns.buildRow(
        valuesByField: {'note': 'x'},
        columnLetters: {'note': 'AA'},
      );
      expect(row.length, 27);
      expect(row[26], 'x');
    });

    test('skips fields with an invalid or missing letter', () {
      final row = SheetColumns.buildRow(
        valuesByField: {'serial': 1, 'bogus': 2, 'other': 3},
        columnLetters: {'serial': 'A', 'bogus': '??'},
      );
      expect(row, [1]);
    });
  });

  group('maxLetterOf', () {
    test('returns the widest mapped column', () {
      expect(
        SheetColumns.maxLetterOf({'a': 'A', 'b': 'C', 'c': 'B'}),
        'C',
      );
      expect(SheetColumns.maxLetterOf({'a': 'A', 'b': 'AB'}), 'AB');
    });
  });

  group('duplicateFields', () {
    test('flags fields sharing a column', () {
      final dupes = SheetColumns.duplicateFields({
        'serial': 'A',
        'date': 'B',
        'time': 'b', // same as date, different case
        'statement': 'D',
      });
      expect(dupes, {'date', 'time'});
    });

    test('is empty for a clean mapping', () {
      expect(
        SheetColumns.duplicateFields({'serial': 'A', 'date': 'B'}),
        isEmpty,
      );
    });
  });
}
