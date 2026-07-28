import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots to level select showing all 10 levels', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // GridView.builder only builds on-screen items — use a tall viewport so
    // all 10 level cards are visible without needing to scroll.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PixelGuessApp()));
    await tester.pumpAndSettle();

    expect(find.text('PixelGuess'), findsOneWidget);
    for (var id = 1; id <= 10; id++) {
      expect(find.text('$id'), findsOneWidget);
    }

    // Unmount so ProviderScope disposes its container — otherwise the
    // energy ticker's periodic Timer outlives the widget tree and trips
    // the test framework's "no pending timers" invariant check. One more
    // pump lets the disposal-triggered subscription cancellation's
    // microtask actually flush before the test ends.
    await tester.pumpWidget(const SizedBox());
    // autoDispose providers debounce disposal by one tick (a zero-duration
    // Timer) so a widget that unsubscribes and resubscribes within the
    // same frame doesn't churn — advance fake time past that tick so the
    // ticker's periodic Timer is actually cancelled before test teardown.
    await tester.pump(const Duration(milliseconds: 1));
  });
}
