import 'dart:typed_data';
import 'dart:ui' as ui;

import 'pixel_dimensions.dart';

/// Decodes source images at a genuinely reduced resolution (hard-edged
/// blockiness, not a blurred downscale) and caches the resulting frames
/// keyed by (levelId, intensity). Callers own an instance's lifecycle and
/// must call [dispose] (or [evictLevel]) when done with it so decoded
/// frames don't leak.
class PixelationService {
  final _cache = <String, ui.Image>{};

  Future<ui.Image> imageFor({
    required int levelId,
    required int intensity,
    required Uint8List sourceBytes,
  }) async {
    final key = _cacheKey(levelId, intensity);
    final cached = _cache[key];
    if (cached != null) return cached;

    final sourceSize = await _peekSize(sourceBytes);
    final dimensions = PixelDimensions.forIntensity(
      sourceWidth: sourceSize.width,
      sourceHeight: sourceSize.height,
      intensity: intensity,
    );

    final codec = await ui.instantiateImageCodec(
      sourceBytes,
      targetWidth: dimensions.width,
      targetHeight: dimensions.height,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();

    _cache[key] = frame.image;
    return frame.image;
  }

  /// Reads a source image's intrinsic dimensions without a full decode
  /// where possible. `ui.ImageDescriptor.width`/`.height` — the cheap
  /// header-only path — throws `UnsupportedError` on Flutter web, so
  /// that platform falls back to a one-off full decode purely to read
  /// the size; every other platform uses the cheap path.
  Future<({int width, int height})> _peekSize(Uint8List bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (width: descriptor.width, height: descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      final probeCodec = await ui.instantiateImageCodec(bytes);
      final probeFrame = await probeCodec.getNextFrame();
      final size = (width: probeFrame.image.width, height: probeFrame.image.height);
      probeFrame.image.dispose();
      probeCodec.dispose();
      return size;
    }
  }

  /// Disposes and drops every cached frame for [levelId] — call this when
  /// leaving the puzzle screen for that level.
  void evictLevel(int levelId) {
    final prefix = '$levelId:';
    final keysToRemove = _cache.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key)?.dispose();
    }
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  String _cacheKey(int levelId, int intensity) => '$levelId:$intensity';
}
