import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:team_sync/services/bound_stats_importer_service.dart';

void main() {
  test('BoundStatsImporterService parses Soccer HTML stats correctly',
      () async {
    const htmlContent = '''
<html>
<body>
  <div class="table-responsive">
    <table>
      <thead>
         <tr>
             <td>Athlete</td>
             <td>GP</td>
             <td>GS</td>
             <td>G</td>
             <td>AST</td>
             <td>PTS</td>
             <td>SV</td>
         </tr>
      </thead>
      <tbody>
        <tr>
          <td>10, Messi, SR</td>
          <td><span>5</span></td> <!-- GP -->
          <td><span>5</span></td> <!-- GS -->
          <td><span>3</span></td> <!-- Goals -->
          <td><span>2</span></td> <!-- Assists -->
          <td><span>8</span></td> <!-- Points -->
          <td><span>0</span></td> <!-- Saves -->
        </tr>
      </tbody>
    </table>
  </div>
</body>
</html>
    ''';

    final mockClient = MockClient((request) async {
      return http.Response(htmlContent, 200);
    });

    final service = BoundStatsImporterService(client: mockClient);
    final rows = await service.parseStats(
      url: 'https://bound.cat/stats_soccer',
      teamId: 55,
      seasonId: 3,
    );

    expect(rows.length, equals(1));
    final data = rows[0].data;

    expect(data['jerseyNumber'], equals(10));
    expect(data['name'], equals('Messi'));
    expect(data['GP'], equals(5));
    expect(data['Goals'], equals(3));
    expect(data['AST'], equals(2));

    // Check that basketball stats are 0 or null
    expect(data['ORB'], equals(0));
  });
}
