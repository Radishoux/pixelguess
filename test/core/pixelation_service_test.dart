import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/pixelation/pixelation_service.dart';

Future<Uint8List> _solidPng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imageFor decodes at the intensity-scaled target size', () async {
    final bytes = await _solidPng(100, 100);
    final service = PixelationService();
    final image = await service.imageFor(levelId: 1, intensity: 10, sourceBytes: bytes);
    expect(image.width, 10);
    expect(image.height, 10);
    service.dispose();
  });

  test('imageFor caches by (levelId, intensity) and returns the same image', () async {
    final bytes = await _solidPng(64, 64);
    final service = PixelationService();
    final first = await service.imageFor(levelId: 2, intensity: 25, sourceBytes: bytes);
    final second = await service.imageFor(levelId: 2, intensity: 25, sourceBytes: bytes);
    expect(identical(first, second), isTrue);
    service.dispose();
  });

  test('imageFor treats different intensities as distinct cache entries', () async {
    final bytes = await _solidPng(64, 64);
    final service = PixelationService();
    final low = await service.imageFor(levelId: 3, intensity: 1, sourceBytes: bytes);
    final high = await service.imageFor(levelId: 3, intensity: 50, sourceBytes: bytes);
    expect(low.width, isNot(equals(high.width)));
    service.dispose();
  });

  test("evictLevel disposes only that level's cached frames", () async {
    final bytes = await _solidPng(64, 64);
    final service = PixelationService();
    final beforeEvict4 = await service.imageFor(levelId: 4, intensity: 1, sourceBytes: bytes);
    final beforeEvict5 = await service.imageFor(levelId: 5, intensity: 1, sourceBytes: bytes);

    service.evictLevel(4);

    final afterEvict4 = await service.imageFor(levelId: 4, intensity: 1, sourceBytes: bytes);
    final afterEvict5 = await service.imageFor(levelId: 5, intensity: 1, sourceBytes: bytes);

    expect(identical(beforeEvict4, afterEvict4), isFalse);
    expect(identical(beforeEvict5, afterEvict5), isTrue);
    service.dispose();
  });
}
