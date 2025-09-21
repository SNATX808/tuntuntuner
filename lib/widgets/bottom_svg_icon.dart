import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomSvgIcon extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final double size;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;

  const BottomSvgIcon({
    super.key,
    required this.asset,
    required this.onTap,
    required this.selected,
    this.size = 28,
    this.selectedColor = Colors.white,
    this.unselectedColor = const Color(0x66FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    final scale = selected ? 1.1 : 1.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 28,
        height: 48,
        child: Center(
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            child: SvgPicture.asset(
              asset,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
