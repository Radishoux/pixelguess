import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/pixelation/pixel_dimensions.dart';

void main() {
  group('PixelDimensions.forIntensity', () {
    test('512x512 source at intensity 1 gives the intended 5x5 starting point', () {
      final dims = PixelDimensions.forIntensity(sourceWidth: 512, sourceHeight: 512, intensity: 1);
      expect(dims.width, 5);
      expect(dims.height, 5);
    });

    test('rounds down, not to nearest', () {
      // 512 * 3 / 100 = 15.36 -> floors to 15
      final dims = PixelDimensions.forIntensity(sourceWidth: 512, sourceHeight: 512, intensity: 3);
      expect(dims.width, 15);
    });

    test('never goes below 1 pixel even when the floored result is 0', () {
      // 10 * 1 / 100 = 0.1 -> floors to 0 -> clamped to 1
      final dims = PixelDimensions.forIntensity(sourceWidth: 10, sourceHeight: 10, intensity: 1);
      expect(dims.width, 1);
      expect(dims.height, 1);
    });

    test('at intensity 100 returns the exact source size', () {
      final dims = PixelDimensions.forIntensity(sourceWidth: 512, sourceHeight: 512, intensity: 100);
      expect(dims.width, 512);
      expect(dims.height, 512);
    });

    test('supports non-square source images independently per axis', () {
      final dims = PixelDimensions.forIntensity(sourceWidth: 400, sourceHeight: 200, intensity: 50);
      expect(dims.width, 200);
      expect(dims.height, 100);
    });

    test('handles a 1px source without going to zero', () {
      final dims = PixelDimensions.forIntensity(sourceWidth: 1, sourceHeight: 1, intensity: 1);
      expect(dims.width, 1);
      expect(dims.height, 1);
    });
  });
}
