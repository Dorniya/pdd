import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yoga_app/screens/yoga/yoga_detail_screen.dart';

void main() {
  testWidgets('Yoga detail screen shows session information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: YogaDetailScreen(
          title: 'Morning Energy Yoga',
          subtitle: '15 min beginner flow',
          description: 'Boost your energy and start fresh',
        ),
      ),
    );

    expect(find.text('Morning Energy Yoga'), findsWidgets);
    expect(find.text('15 min beginner flow'), findsOneWidget);
    expect(find.text('Boost your energy and start fresh'), findsOneWidget);

    expect(find.text('Start Session'), findsOneWidget);
  });
}
