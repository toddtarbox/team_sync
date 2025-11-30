import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/screen_size_helper.dart';

/// Golden tests example for verifying visual appearance across screen sizes
///
/// To update golden files: flutter test --update-goldens
/// To run tests: flutter test
///
/// NOTE: To test your actual TeamHomePage, you'll need to provide mocked
/// dependencies and test data. This example uses a simple widget.

class GoldenTestWidget extends StatelessWidget {
  const GoldenTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Golden Test'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'TeamSync',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('${size.width.toInt()} x ${size.height.toInt()}'),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('Golden Tests Example', () {
    testWidgets('golden test on small screen', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.small);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const GoldenTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GoldenTestWidget),
        matchesGoldenFile('goldens/test_widget_small.png'),
      );

      await tester.resetScreenSize();
    });

    testWidgets('golden test on medium screen', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const GoldenTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GoldenTestWidget),
        matchesGoldenFile('goldens/test_widget_medium.png'),
      );

      await tester.resetScreenSize();
    });

    testWidgets('golden test on large screen', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.large);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const GoldenTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GoldenTestWidget),
        matchesGoldenFile('goldens/test_widget_large.png'),
      );

      await tester.resetScreenSize();
    });
  });

  group('Dark Mode Golden Tests', () {
    testWidgets('golden test dark mode on medium screen',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const GoldenTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GoldenTestWidget),
        matchesGoldenFile('goldens/test_widget_dark_medium.png'),
      );

      await tester.resetScreenSize();
    });
  });
}
