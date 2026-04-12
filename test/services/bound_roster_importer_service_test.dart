import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:team_sync/services/bound_roster_importer_service.dart';

void main() {
  test('BoundRosterImporterService parses HTML roster with dynamic columns',
      () async {
    const htmlContent = '''
<html>
<body>
  <table>
    <tr>
      <td>#</td>
      <td>Name</td>
      <td>Year</td>
      <td>Pos</td>
      <!-- Missing Height column -->
    </tr>
    <tr>
      <td class="text-center font-weight-bold">2</td>
      <td><h7 class="font-weight-bold">Bryce Nelson</h7></td>
      <td>FR</td>
      <td class="text-center">G</td>
    </tr>
     <tr>
      <td>23</td>
      <td>John Doe</td>
      <td>SR</td>
      <td>F</td>
    </tr>
  </table>
</body>
</html>
    ''';

    final mockClient = MockClient((request) async {
      return http.Response(htmlContent, 200);
    });

    final service = BoundRosterImporterService(client: mockClient);
    final rows = await service.parseRoster(
      url: 'https://bound.cat/roster',
      teamId: 55,
      seasonId: 3,
    );

    expect(rows.length, equals(2));

    // Player 1
    expect(rows[0].data['number'], equals(2));
    expect(rows[0].data['name'], equals('Bryce Nelson'));
    expect(rows[0].data['firstName'], equals('Bryce'));
    expect(rows[0].data['lastName'], equals('Nelson'));
    expect(rows[0].data['classYear'], equals('FR'));
    expect(rows[0].data['position'], equals('G'));
    expect(rows[0].data['height'], isEmpty); // Missing height

    // Player 2
    expect(rows[1].data['number'], equals(23));
  });
}
