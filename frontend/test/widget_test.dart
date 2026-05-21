// Basic smoke test: app builds and renders a frame.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:memories_app/main.dart';

void main() {
  testWidgets('App boots without error', (WidgetTester tester) async {
    // Avoid runtime font fetching (network) which leaves pending timers in tests.
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const ProviderScope(child: MemoriesApp()));
    // Drain demo-data Future.delayed timers and redirects.
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
