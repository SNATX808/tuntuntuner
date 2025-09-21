import 'package:flutter/material.dart';

class RectThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;
  const RectThumbShape({this.thumbWidth = 6, this.thumbHeight = 18});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(thumbWidth, thumbHeight);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final canvas = context.canvas;
    final paint = Paint()..color = sliderTheme.thumbColor ?? Colors.white;
    final rect = Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight);
    canvas.drawRect(rect, paint);
  }
}

class RectSliderTrackShape extends SliderTrackShape {
  const RectSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
    Offset offset = Offset.zero,
  }) {
    final h = sliderTheme.trackHeight ?? 4.0;
    final top = offset.dy + (parentBox.size.height - h) / 2;
    return Rect.fromLTWH(offset.dx, top, parentBox.size.width, h);
  }

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required Animation<double> enableAnimation,
        required TextDirection textDirection,
        required Offset thumbCenter,
        Offset? secondaryOffset,
        bool isDiscrete = false,
        bool isEnabled = false,
        double additionalActiveTrackHeight = 2,
      }) {
    final canvas = context.canvas;
    final rect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
      offset: offset,
    );

    final active = Paint()..color = sliderTheme.activeTrackColor ?? Colors.white;
    final inactive = Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final left = textDirection == TextDirection.ltr
        ? Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom)
        : Rect.fromLTRB(thumbCenter.dx, rect.top, rect.right, rect.bottom);
    final right = textDirection == TextDirection.ltr
        ? Rect.fromLTRB(thumbCenter.dx, rect.top, rect.right, rect.bottom)
        : Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom);

    canvas.drawRect(left, active);
    canvas.drawRect(right, inactive);
  }
}
