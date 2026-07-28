import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks once a second purely to trigger a rebuild of widgets showing a
/// live energy countdown. The actual regen math is always re-derived
/// from the persisted timestamp (see EnergyEngine), never from this
/// ticker's count, so missed ticks (app backgrounded) are harmless.
///
/// autoDispose so the underlying periodic Timer is torn down as soon as
/// nothing is watching it. Built on an explicit `Timer.periodic` +
/// `ref.onDispose` (rather than `Stream.periodic`) so cancellation is
/// synchronous and guaranteed on disposal — `Stream.periodic`'s own
/// cancellation timing is not reliably synchronous with provider teardown.
final energyTickerProvider = StreamProvider.autoDispose<int>((ref) {
  final controller = StreamController<int>();
  var tick = 0;
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    controller.add(tick++);
  });
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});
