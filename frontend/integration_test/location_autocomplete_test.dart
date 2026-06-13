// Integration test: verifies LocationAutocompleteField inside a real
// showModalBottomSheet on a device/simulator, against LIVE Nominatim.
//
// Confirms:
//   1. Typing >=3 chars triggers a Nominatim search and the suggestion
//      overlay renders ABOVE the bottom sheet (the InkWell is hit-testable
//      and tappable — proving correct z-order, not clipped/behind).
//   2. Tapping a suggestion fills the field and fires onSelected with coords.
//
// Run: flutter test integration_test/location_autocomplete_test.dart -d <device>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memories_app/core/location/geocoding_service.dart';
import 'package:memories_app/shared/widgets/location_autocomplete_field.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('autocomplete dropdown renders above bottom sheet and fills on tap',
      (tester) async {
    final controller = TextEditingController();
    PlaceSuggestion? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 200),
                          LocationAutocompleteField(
                            controller: controller,
                            onSelected: (s) => selected = s,
                          ),
                          const SizedBox(height: 200),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open the bottom sheet.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(LocationAutocompleteField), findsOneWidget);

    // Type a query; wait past the 400ms debounce + the live network call.
    await tester.enterText(find.byType(TextFormField), 'ubud');
    await tester.pump(const Duration(milliseconds: 500)); // debounce fires
    // Poll for the network result to land in the overlay.
    var found = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.textContaining('Ubud').evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    expect(found, isTrue,
        reason: 'Nominatim suggestion containing "Ubud" should render in the overlay');

    // The suggestion lives in an OverlayEntry inserted ABOVE the sheet route.
    // Tapping it proves it is hit-testable (on top), not behind the sheet.
    final suggestion = find.textContaining('Ubud').first;
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    // Field filled + onSelected fired with real coords.
    expect(controller.text.toLowerCase(), contains('ubud'));
    expect(selected, isNotNull);
    expect(selected!.lat, closeTo(-8.5, 0.6));
    expect(selected!.lng, closeTo(115.26, 0.6));
  });
}
