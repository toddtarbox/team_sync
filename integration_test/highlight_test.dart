import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:team_sync/main_team_sync.dart' as app;

const int playbackSpeed = 1;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, int seconds) async {
    await Future.delayed(
        Duration(milliseconds: (seconds * 1000 / playbackSpeed).toInt()));
    await tester.pumpAndSettle();
  }

  testWidgets('Highlight Reel Automation', (WidgetTester tester) async {
    // Launch the app
    app.main();

    await wait(tester, 3); // Give time for the recorder to start

    // Clear preferences before starting the app
    // Note: In integration_test, simple SharedPreferences.getInstance() works
    // because it runs in the same process.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('team_accomplishments_expanded');
    await prefs.remove('team_recent_games_expanded');
    await prefs.remove('team_analytics_expanded');

    debugPrint('--- Starting Highlight Reel ---');

    // 1. Explore Team Home Page (Analytics & Records)
    await tester.showDemoMessage(
        'Team Home Page\nAnalytics, Records & Accomplishments');
    await tester.pumpAndSettle();

    // Highlight the team and organization images
    await tester.highlightWidget(find.byKey(const Key('team_logo')).first,
        message: 'Team Logo', duration: const Duration(seconds: 2));
    await tester.highlightWidget(
        find.byKey(const Key('organization_logo')).first,
        message: 'Organization Logo',
        duration: const Duration(seconds: 2));

    // Expand "Recent Games"
    final recentGamesIcon = find.byKey(const Key('recent_games_header'));
    await tester.tap(recentGamesIcon.first);
    await tester.pumpAndSettle();
    await wait(tester, 1);
    await tester.loopThroughCarousel(2, finder: find.byType(Card));
    // Collapse "Recent Games"
    await tester.tap(recentGamesIcon.first);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Expand "Team Performance" (Analytics) Section
    final analyticsSectionIcon = find.byKey(const Key('analytics_header'));
    await tester.tap(analyticsSectionIcon.first);
    await tester.pumpAndSettle();
    await wait(tester, 1);
    await tester.loopThroughCarousel(3);
    // Collapse "Team Performance"
    await tester.tap(analyticsSectionIcon.first);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Expand "Team Accomplishments" Section
    final accomplishmentsText = find.byKey(const Key('accomplishments_header'));
    await tester.tap(accomplishmentsText.first);
    await tester.pumpAndSettle();
    await wait(tester, 1);
    // Scroll accomplishments
    await tester.smoothDrag(find.byType(Card).first, const Offset(0, -200),
        waitAfter: 1);
    // Scroll back to top
    await tester.smoothDrag(find.byType(Card).first, const Offset(0, 200),
        waitAfter: 1);
    // Collapse "Team Accomplishments"
    await tester.tap(accomplishmentsText.first);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    await tester.showDemoMessage(
        'Track Record Holders\nAcross Games, Seasons & Careers');

    // Navigate to Records Page via Menu
    final menuIcon = find.byIcon(Icons.more_vert);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Select "Records"
    final recordsItem = find.byIcon(Icons.leaderboard);
    await tester.tap(recordsItem);
    await tester.pumpAndSettle();
    await wait(tester, 2);
    // Scroll records
    await tester.smoothDrag(find.byType(Card).first, const Offset(0, -200),
        waitAfter: 2);
    // Scroll back to top
    await tester.smoothDrag(find.byType(Card).first, const Offset(0, 200),
        waitAfter: 2);

    // Go back
    await tester.navigateBack();

    await tester.showDemoMessage('Track Team Analytics & History');

    // Navigate to Analytics (History) Page via Menu
    // Note: Menu icon must be tapped again
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Select "Analytics" (History) - Uses analytics_outlined
    final historyItem = find.byIcon(Icons.analytics_outlined);
    await tester.tap(historyItem);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Swipe left to view more analytics
    await tester.loopThroughCarousel(3);

    // Go back
    await tester.navigateBack();

    await tester.showDemoMessage('Review Season Details');

    // Scroll down a bit
    final seasonCard = find.text('Spring 2025');
    await tester.smoothScrollUntilVisible(seasonCard, 300);

    // 2. Navigate to 2025 Season
    debugPrint('Navigating to Spring 2025 Season...');
    await tester.tap(seasonCard);
    await tester.pumpAndSettle();
    await wait(tester, 3);

    // 3. Explore Games in Season Page
    debugPrint('Exploring Games List...');

    await tester.showDemoMessage('Deep Dive into Game Details & Analytics');

    // Scroll down a bit
    await tester.smoothScrollUntilVisible(find.text('@ Glenwood'), 200);
    await tester.pumpAndSettle();
    await wait(tester, 2);

    // Tap a game
    final gameCard = find.textContaining('@ Glenwood').first;
    await tester.tap(gameCard);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Handle mobile "Go to game" button in bottom sheet
    final goToGameButton = find.text('Go to game');
    await tester.tap(goToGameButton);
    await tester.pumpAndSettle();
    await wait(tester, 3);

    await tester
        .showDemoMessage('Review Scoring Summary & All Game Events & Stats');

    // Scroll down a bit
    await tester.smoothScrollUntilVisible(find.text('7 - 0'), 400);
    await tester.pumpAndSettle();
    await wait(tester, 2);

    // Explore Game Stats
    debugPrint('Exploring Game Stats...');
    final statsIcon = find.byIcon(Icons.analytics);
    await tester.tap(statsIcon);
    await tester.pumpAndSettle();
    await wait(tester, 4);

    // Go back
    await tester.navigateBack();

    // Return to Season Page
    await tester.navigateBack();

    await tester.showDemoMessage('Season Details & Analytics');

    // Navigate to Season Stats
    debugPrint('Navigating to Season Stats...');
    final seasonStatsIcon = find.byIcon(Icons.analytics);
    await tester.tap(seasonStatsIcon);
    await tester.pumpAndSettle();
    await wait(tester, 4);

    // Select Goals Card
    final goalsCard = find.text('Goals');
    await tester.tap(goalsCard);
    await tester.pumpAndSettle();
    await wait(tester, 4);

    await tester
        .showDemoMessage('Detailed Player Profiles\nPerfect for recruiting!');

    // Navigate to Kyle Irwin's Player Profile
    final playerCard = find.text('Kyle Irwin');
    await tester.tap(playerCard);
    await tester.pumpAndSettle();
    await wait(tester, 4);

    await tester.showDemoMessage('Create Informative Player Cards to Share');

    // Select Player Card Action Icon (Generate Card)
    final actionIcon = find.byIcon(Icons.stars);
    await tester.tap(actionIcon);
    await tester.pumpAndSettle();
    await wait(tester, 5); // Wait for dialog
    // Tap Show Stats button
    final showStatsButton = find.text('Show Stats');
    await tester.tap(showStatsButton);
    await tester.pumpAndSettle();
    await wait(tester, 5); // Wait for stats to load

    // Close dialog
    await tester.navigateBack();

    await tester.showDemoMessage(
        'Showcase Player Highlights\nPerfect for social media!');

    // Open Highlights Modal (Mobile)

    debugPrint('Opening Highlights Modal...');
    final videoIcon = find.byIcon(Icons.video_library);
    await tester.tap(videoIcon);
    await tester.pumpAndSettle();
    await wait(tester, 3);

    // Close modal
    await tester.navigateBack();

    await tester.showDemoMessage('Share your profile with the world!');

    // Tap on the Barcode Icon
    final barcodeIcon = find.byIcon(Icons.qr_code_2);
    await tester.tap(barcodeIcon);
    await tester.pumpAndSettle();
    await wait(tester, 3);

    // Close modal
    await tester.navigateBack();

    // Go back
    await tester.navigateBack();

    // Go back
    await tester.navigateBack();

    // Return to Season Page
    await tester.navigateBack();

    // Return to Home Page
    await tester.navigateBack();

    await tester.showDemoMessage(
        'Share all of these details with your players, parents, and fans\nautomatically, on your dedicated team website!');

    await tester.tap(menuIcon);
    await tester.pumpAndSettle();
    await wait(tester, 1);

    // Select the Share Icon from the Menu
    final shareIcon = find.byIcon(Icons.share);
    await tester.tap(shareIcon);
    await tester.pumpAndSettle();
    await wait(tester, 3);

    // Close modal
    await tester.navigateBack();

    await tester
        .showDemoMessage('All of this and more awaits!\n\nGet started today!');

    debugPrint('--- Highlight Reel Finished ---');
    await wait(tester, 2);
  });
}

extension WidgetTesterExtensions on WidgetTester {
  Future<void> showDemoMessage(String message, {Duration? duration}) async {
    final navigator = state(find.byType(Navigator).last) as NavigatorState;

    // Push a dark overlay page
    navigator.push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.85),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await pumpAndSettle();

    // Hold the message
    duration ??= Duration(milliseconds: (3000 / playbackSpeed).toInt());
    await Future.delayed(duration);

    // Pop the page
    navigator.pop();
    await pumpAndSettle();
  }

  Future<void> smoothDrag(Finder finder, Offset offset,
      {Duration duration = const Duration(milliseconds: 500),
      int waitAfter = 0}) async {
    await timedDrag(finder, offset, duration, warnIfMissed: false);
    await pumpAndSettle();

    if (waitAfter > 0) {
      final waitDuration =
          Duration(milliseconds: (waitAfter / playbackSpeed).toInt());
      await Future.delayed(waitDuration);
      await pumpAndSettle();
    }
  }

  Future<void> smoothScrollUntilVisible(Finder finder, double delta,
      {Duration duration = const Duration(milliseconds: 300),
      int maxScrolls = 50,
      Finder? scrollable}) async {
    Finder scrollableFinder = scrollable ?? find.byType(Scrollable).first;
    for (int i = 0; i < maxScrolls; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await smoothDrag(scrollableFinder, Offset(0, -delta), duration: duration);
    }
    // Final check
    if (finder.evaluate().isEmpty) {
      throw Exception(
          'Could not find $finder after scrolling $maxScrolls times');
    }
  }

  Future<void> navigateBack({int waitAfter = 2}) async {
    final backTooltip = find.byTooltip('Back');
    final backIcon = find.byIcon(Icons.arrow_back);
    final closeIcon = find.byIcon(Icons.close);
    final closeText = find.text('Close');

    if (closeText.evaluate().isNotEmpty) {
      await tap(closeText.first, warnIfMissed: false);
    } else if (backTooltip.evaluate().isNotEmpty) {
      await tap(backTooltip.first, warnIfMissed: false);
    } else if (backIcon.evaluate().isNotEmpty) {
      await tap(backIcon.first, warnIfMissed: false);
    } else if (closeIcon.evaluate().isNotEmpty) {
      await tap(closeIcon.first, warnIfMissed: false);
    }

    await pumpAndSettle();
    if (waitAfter > 0) {
      await Future.delayed(Duration(seconds: waitAfter));
      await pumpAndSettle();
    }
  }

  Future<void> loopThroughCarousel(
    int loops, {
    Finder? finder,
    Offset offset = const Offset(-200, 0),
    Duration duration = const Duration(milliseconds: 500),
    int waitAfter = 1,
  }) async {
    if (finder == null) {
      finder = find.byType(CarouselSlider);
      for (int i = 0; i < loops; i++) {
        await smoothDrag(finder.first, offset,
            duration: duration, waitAfter: waitAfter);
      }
    } else {
      for (int i = 0; i < loops; i++) {
        await smoothDrag(finder.at(i), offset,
            duration: duration, waitAfter: waitAfter);
      }
    }
  }

  Future<void> highlightWidget(
    Finder finder, {
    String? message,
    Duration duration = const Duration(seconds: 2),
    Color color = Colors.red,
    double strokeWidth = 6.0,
    double padding = 0.0,
  }) async {
    final element = finder.evaluate().first;
    final renderObject = element.renderObject as RenderBox;
    final size = renderObject.size;
    final offset = renderObject.localToGlobal(Offset.zero);

    final navigator = state(find.byType(Navigator).last) as NavigatorState;

    // Push a transparent overlay page
    navigator.push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, __) => Stack(
          children: [
            // The Highlight Box
            Positioned(
              left: offset.dx - padding,
              top: offset.dy - padding,
              width: size.width + (padding * 2),
              height: size.height + (padding * 2),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: strokeWidth),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
            // Optional Message Text
            if (message != null)
              Positioned(
                left: 0,
                right: 0,
                top: offset.dy - 80 < 50
                    ? offset.dy + size.height + 20
                    : offset.dy - 80, // Position below if too close to top
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    await pumpAndSettle();

    // Hold the highlight
    await Future.delayed(duration);

    // Pop the page
    navigator.pop();
    await pumpAndSettle();
  }
}
