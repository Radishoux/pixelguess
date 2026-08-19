import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/pixelation/pixelation_service.dart';

/// Renders the level image at [intensity] via [pixelation], cross-fading
/// between resolutions whenever intensity changes so a reveal purchase
/// feels like a reward. [FilterQuality.none] is mandatory so the low-res
/// frame stays crisp hard-edged squares rather than being smoothed.
///
/// The previously-loaded frame is kept on screen while the next intensity
/// decodes, so [AnimatedSwitcher] can cross-fade directly from the old
/// resolution to the new one instead of flashing an empty gap between them.
class PixelatedImage extends StatefulWidget {
  const PixelatedImage({
    super.key,
    required this.pixelation,
    required this.levelId,
    required this.intensity,
    required this.sourceBytes,
  });

  final PixelationService pixelation;
  final int levelId;
  final int intensity;
  final Uint8List sourceBytes;

  @override
  State<PixelatedImage> createState() => _PixelatedImageState();
}

class _PixelatedImageState extends State<PixelatedImage> {
  ui.Image? _image;
  int? _imageIntensity;

  @override
  void initState() {
    super.initState();
    _loadAndSet();
  }

  @override
  void didUpdateWidget(covariant PixelatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity || oldWidget.levelId != widget.levelId) {
      _loadAndSet();
    }
  }

  Future<void> _loadAndSet() async {
    final targetLevelId = widget.levelId;
    final targetIntensity = widget.intensity;
    final image = await widget.pixelation.imageFor(
      levelId: targetLevelId,
      intensity: targetIntensity,
      sourceBytes: widget.sourceBytes,
    );
    if (!mounted) return;
    // If intensity/level moved on again while this decode was in flight,
    // drop the now-stale result rather than rendering it out of order.
    if (widget.levelId != targetLevelId || widget.intensity != targetIntensity) return;
    setState(() {
      _image = image;
      _imageIntensity = targetIntensity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: image == null
          ? const SizedBox.shrink(key: ValueKey('pixelated-image-loading'))
          : RawImage(
              key: ValueKey(_imageIntensity),
              image: image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
    );
  }
}
