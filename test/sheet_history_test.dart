import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mysheetapp/core/errors/app_exception.dart';
import 'package:mysheetapp/data/services/google_sheets_service.dart';

class TestAuthClient extends MockClient implements AuthClient {
  TestAuthClient(super.handler);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const mapping = {'serial': 'C', 'statement': 'A', 'debit': 'E', 'note': 'F'};
  GoogleSheetsService service(
    Future<http.Response> Function(http.Request) handler,
  ) => GoogleSheetsService(
    client: TestAuthClient(handler),
    spreadsheetId: 'test',
    sheetName: "Owner's ledger",
    columnLetters: mapping,
  );

  test(
    'reads manual rows after 150 using mapped serial, not physical row',
    () async {
      final sheet = service((request) async {
        expect(request.url.queryParameters['valueRenderOption'], 'FORMULA');
        expect(
          Uri.decodeComponent(request.url.path),
          contains("'Owner''s ledger'!A2:F"),
        );
        return http.Response(
          jsonEncode({
            'values': [
              ['old', '', 150],
              ['manual', '', 151, '', 12.5],
              [],
              ['later', '', '١٥٣', '', '=SUM(A1:A2)'],
              ['total', '', 'Total'],
            ],
          }),
          200,
        );
      });
      final rows = await sheet.fetchEntries();
      expect(rows.map((r) => r.serial), [151, 153]);
      expect(rows.first.text('statement'), 'manual');
      expect(rows.last.text('debit'), '=SUM(A1:A2)');
      expect(rows.first.text('note'), '');
    },
  );

  test(
    're-resolves shifted rows and writes only changed cells as raw values',
    () async {
      final writes = <Map<String, dynamic>>[];
      final sheet = service((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'values': [
                [],
                ['manual', '', 151, '', 20],
              ],
            }),
            200,
          );
        }
        writes.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{}', 200);
      });
      await sheet.updateEntryBySerial(
        const SheetLedgerRow(
          serial: 151,
          values: {
            'serial': 151,
            'statement': 'manual',
            'debit': 20,
            'note': '',
          },
        ),
        {'note': '=literal note'},
      );
      expect(writes.single['valueInputOption'], 'RAW');
      expect(writes.single['data'], [
        {
          'range': "'Owner''s ledger'!F3",
          'values': [
            ['=literal note'],
          ],
        },
      ]);
    },
  );

  for (final scenario in ['missing', 'duplicate', 'changed']) {
    test('rejects $scenario serial without any write', () async {
      final sheet = service((request) async {
        expect(request.method, 'GET');
        final rows = scenario == 'missing'
            ? []
            : scenario == 'duplicate'
            ? [
                ['manual', '', 151],
                ['manual', '', 151],
              ]
            : [
                ['changed externally', '', 151],
              ];
        return http.Response(jsonEncode({'values': rows}), 200);
      });
      await expectLater(
        sheet.updateEntryBySerial(
          const SheetLedgerRow(
            serial: 151,
            values: {'serial': 151, 'statement': 'manual'},
          ),
          {'statement': 'new'},
        ),
        throwsA(isA<SheetsException>()),
      );
    });
  }

  test(
    'serial parsing accepts Arabic/Persian digits and rejects invalid IDs',
    () {
      expect(SheetLedgerRow.parseSerial('۱۵۱'), 151);
      expect(SheetLedgerRow.parseSerial('١٥٢'), 152);
      expect(SheetLedgerRow.parseSerial(151.0), 151);
      for (final value in ['151.5', 'NaN', 'Infinity', '-1', 'total']) {
        expect(SheetLedgerRow.parseSerial(value), isNull);
      }
    },
  );
}
