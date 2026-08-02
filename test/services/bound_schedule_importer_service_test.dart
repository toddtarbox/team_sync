import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:team_sync/features/data_import/services/bound_schedule_importer_service.dart';

void main() {
  test('BoundScheduleImporterService parses HTML schedule correctly', () async {
    const htmlContent = '''
<html>
<body>
  <table>
    <tr>
      <td>Lo-Ma Boys Basketball Scrimmage</td>
      <td><a href="/ia/ihsaa/boysbasketball/2025-26/comps/h2025110606234134672cfc68b51ab44">9:00 AM</a></td>
      <td>Location</td>
    </tr>
    <tr>
      <td><a href="/school">Exira-EHK</a></td>
      <td><a href="/ia/ihsaa/boysbasketball/2025-26/comps/h20251117051509798457e00d5097449">7:30 PM</a></td>
    </tr>
    <tr>
      <td>vs <a href="/school">Clarinda</a></td>
      <td><a href="/ia/ihsaa/boysbasketball/2025-26/comps/h20250710081657228e8e740bc38a14b">W 57-46</a></td>
    </tr>
    <tr>
      <td><a href="/school">Creston</a></td>
      <td><a href="/ia/ihsaa/boysbasketball/2025-26/comps/h202508041048080163f703f52a75542">W 76-45</a></td>
    </tr>
     <tr>
      <td>@ <a href="/school">Lewis Central</a></td>
      <td><a href="/ia/ihsaa/boysbasketball/2025-26/comps/h2025040803044294089aa4d0dcce444">L 51-63</a></td>
    </tr>
  </table>
</body>
</html>
    ''';

    final mockClient = MockClient((request) async {
      return http.Response(htmlContent, 200);
    });

    final service = BoundScheduleImporterService(client: mockClient);
    final rows = await service.parseSchedule(
      url: 'https://bound.fake/schedule',
      seasonId: 1,
      homeTeamId: 100,
    );

    expect(rows.length, equals(5));

    // Game 0: Lo-Ma Scrimmage (Text opponent)
    // Note: The new parser logic looks for opponent in sibling cells.
    expect(rows[0].data['opponentName'], contains('Lo-Ma'));
    expect(rows[0].data['date'], contains('2025-11-06'));
    expect(rows[0].data['gameStatus'], equals('0')); // Not Started

    // Game 1: Exira-EHK (Link opponent)
    expect(rows[1].data['opponentName'], equals('Exira-EHK'));
    expect(rows[1].data['date'], contains('2025-11-17'));

    // Game 2: Clarinda (vs prefix)
    expect(rows[2].data['opponentName'], equals('Clarinda'));
    expect(rows[2].data['isHome'], isTrue);
    expect(rows[2].data['gameStatus'], equals('9')); // Final
    expect(rows[2].data['homeTeamScore'], equals(57));

    // Game 3: Creston
    expect(rows[3].data['opponentName'], equals('Creston'));
    expect(rows[3].data['homeTeamScore'], equals(76));

    // Game 4: Lewis Central (@ prefix)
    expect(rows[4].data['opponentName'], equals('Lewis Central'));
    expect(rows[4].data['isHome'], isFalse);
    expect(rows[4].data['homeTeamScore'], equals(51)); // Our score
    expect(rows[4].data['awayTeamScore'], equals(63)); // Their score
  });
}
