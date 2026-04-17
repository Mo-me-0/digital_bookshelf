// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_bookshelf/main.dart';

void main() {
  testWidgets('App renders correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app renders the correct title and initial state.
    expect(find.text('My Bookshelf'), findsOneWidget);
    expect(find.text('No file selected'), findsOneWidget);

    // Verify that the buttons are present.
    expect(find.text('Pick a File'), findsOneWidget);
    expect(find.text('Open Selected File'), findsOneWidget);
    expect(find.text('Delete Selected File'), findsOneWidget);
  });
}
