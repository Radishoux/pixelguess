/// Pure dimension math for the pixelation mechanic, kept Flutter-free so
/// the floor/clamp edge cases are testable without decoding real images.
class PixelDimensions {
  final int width;
  final int height;

  const PixelDimensions(this.width, this.height);

  static PixelDimensions forIntensity({
    required int sourceWidth,
    required int sourceHeight,
    required int intensity,
  }) {
    final rawWidth = (sourceWidth * intensity / 100).floor();
    final rawHeight = (sourceHeight * intensity / 100).floor();
    return PixelDimensions(
      rawWidth < 1 ? 1 : rawWidth,
      rawHeight < 1 ? 1 : rawHeight,
    );
  }
}
