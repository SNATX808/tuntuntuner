import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const TukaApp());

class AppTheme {
  static const bgTop = Color(0xFF420909);
  static const accent = Color(0xFFE53935);
  static const textPri = Colors.white;
  static const textSec = Color(0xB3FFFFFF);

  static TextStyle title() => GoogleFonts.alumniSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: textPri,
  );
  static TextStyle artist() => GoogleFonts.alumniSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textSec,
  );
  static ThemeData theme() => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.alumniSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
  );
}

/// Прямоугольный ползунок (квадрат задаётся размерами)
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
    final rect =
    Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight);
    canvas.drawRect(rect, paint);
  }
}

/// Прямоугольный трек
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
    final inactive =
    Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

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

/// Кнопка-квадрат: темнеет при удержании + короткий флэш на быстрый тап
class PressableSquare extends StatefulWidget {
  final double size;
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double darkenAmount; // 0..1
  final Duration releaseDuration; // анимация «отпуска»
  final Duration flashDuration; // флэш для быстрых тапов
  final BorderRadius? borderRadius;

  const PressableSquare({
    super.key,
    required this.size,
    required this.child,
    required this.onTap,
    this.color = Colors.white,
    this.darkenAmount = 0.2,
    this.releaseDuration = const Duration(milliseconds: 120),
    this.flashDuration = const Duration(milliseconds: 100),
    this.borderRadius,
  });

  @override
  State<PressableSquare> createState() => _PressableSquareState();
}

class _PressableSquareState extends State<PressableSquare> {
  bool _pressed = false;
  bool _flashing = false;

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Future<void> _triggerFlash() async {
    if (!mounted) return;
    setState(() => _flashing = true);
    await Future.delayed(widget.flashDuration);
    if (mounted) setState(() => _flashing = false);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color;
    final held = _darken(base, widget.darkenAmount);
    final showDark = _pressed || _flashing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _triggerFlash();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: widget.releaseDuration,
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: showDark ? held : base,
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class TukaApp extends StatelessWidget {
  const TukaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool liked = false;
  bool playing = false;
  double pos = 33;
  final double total = 151;

  // выбранная нижняя иконка: 0=home, 1=search, 2=messages, 3=profile
  int bottomSelected = 0;

  Color dominant = AppTheme.bgTop;
  static const String coverPath = 'assets/draka.png';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    try {
      await precacheImage(const AssetImage(coverPath), context);
      final palette = await PaletteGenerator.fromImageProvider(
        const ResizeImage(AssetImage(coverPath), width: 200),
        maximumColorCount: 20,
      );

      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.darkVibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.mutedColor?.color ??
          AppTheme.bgTop;

      if (mounted) setState(() => dominant = color);
    } catch (_) {
      if (mounted) setState(() => dominant = AppTheme.bgTop);
    }
  }

  String _fmt(double s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).round().toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Color lighten(Color c, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // фон + основной контент
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lighten(dominant, 0.15), Colors.black],
                  stops: const [0.0, 0.8],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  // ======= ВЕРХНИЙ КОНТЕНТ (скролл выключен) =======
                  Expanded(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      primary: false,
                      children: [
                        // Поиск
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: AppTheme.accent,
                            decoration: InputDecoration(
                              hintText: 'Поиск',
                              hintStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 28,
                              ),
                              filled: true,
                              fillColor: const Color.fromRGBO(20, 20, 20, 0.3),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        // Обложка
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: FractionallySizedBox(
                            widthFactor: 0.9,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    coverPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Container(
                                      color: Colors.white12,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Нет изображения\nassets/cover.jpg',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Название / артист / лайк (как было)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(20, -10),
                                    child: Text('Double Цвет', style: AppTheme.title()),
                                  ),
                                  const SizedBox(height: 4),
                                  Transform.translate(
                                    offset: const Offset(20, -30),
                                    child: Text('Tuka', style: AppTheme.artist()),
                                  ),
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(-10, -20),
                              child: IconButton(
                                iconSize: 36,
                                onPressed: () => setState(() => liked = !liked),
                                icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                                color: liked ? AppTheme.accent : AppTheme.textPri,
                              ),
                            ),
                          ],
                        ),

                        // ======= ТАЙМЛАЙН + КНОПКИ (кнопки подняты, кликаются целиком) =======
                        SizedBox(
                          height: 210,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Таймлайн + таймкоды — оставлены на месте
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Transform.translate(
                                  offset: const Offset(0, -30),
                                  child: Column(
                                    children: [
                                      FractionallySizedBox(
                                        widthFactor: 0.9,
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 5,
                                            trackShape: const RectSliderTrackShape(),
                                            activeTrackColor: Colors.white,
                                            inactiveTrackColor: Colors.white54,
                                            thumbColor: Colors.white,
                                            thumbShape: const RectThumbShape(
                                              thumbWidth: 14,
                                              thumbHeight: 14,
                                            ),
                                            overlayShape: SliderComponentShape.noOverlay,
                                          ),
                                          child: Slider(
                                            value: pos,
                                            min: 0,
                                            max: total,
                                            onChanged: (v) => setState(() => pos = v),
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: 0.9,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _fmt(pos),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              _fmt(total),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Кнопки управления — ПОДНЯТЫ (ты ставил top: 10)
                              Positioned(
                                top: 10, // ← как просил
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PressableSquare(
                                      size: 55,
                                      onTap: () { /* prev */ },
                                      child: const Icon(Icons.skip_previous,
                                          color: Colors.black, size: 55),
                                    ),
                                    const SizedBox(width: 20),
                                    PressableSquare(
                                      size: 75,
                                      onTap: () => setState(() => playing = !playing),
                                      child: Icon(
                                        playing ? Icons.pause : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 72, // не больше контейнера
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    PressableSquare(
                                      size: 55,
                                      onTap: () { /* next */ },
                                      child: const Icon(Icons.skip_next,
                                          color: Colors.black, size: 55),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // ======= НИЖНИЙ МИНИМАЛИСТИЧНЫЙ РЯД (SVG, без фона) =======
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BottomSvgIcon(
                            asset: 'assets/icons/home_icon.svg',
                            selected: bottomSelected == 0,
                            unselectedColor: const Color(0x66FFFFFF),
                            onTap: () => setState(() => bottomSelected = 0),
                          ),
                          _BottomSvgIcon(
                            asset: 'assets/icons/search_icon.svg',
                            selected: bottomSelected == 1,
                            unselectedColor: const Color(0x66FFFFFF),
                            onTap: () => setState(() => bottomSelected = 1),
                          ),
                          // Центральный белый квадрат с чёрным плюсом
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 48,
                              height: 48,
                              color: Colors.white,
                              child: const Center(
                                child: Icon(Icons.add, color: Colors.black, size: 36),
                              ),
                            ),
                          ),
                          _BottomSvgIcon(
                            asset: 'assets/icons/messages_icon.svg',
                            selected: bottomSelected == 2,
                            unselectedColor: const Color(0x66FFFFFF),
                            onTap: () => setState(() => bottomSelected = 2),
                          ),
                          _BottomSvgIcon(
                            asset: 'assets/icons/profile_icon.svg',
                            selected: bottomSelected == 3,
                            unselectedColor: const Color(0x66FFFFFF),
                            onTap: () => setState(() => bottomSelected = 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======= БУРГЕР СПРАВА СНИЗУ (над навигацией) =======
          Positioned(
            right: 24,
            bottom: 105, // оставь как удобно
            child: PressableSquare(
              size: 52,
              color: Colors
                  .transparent, // ← белый фон убрали (прозрачный фон, хит-таргет остался 52x52)
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // TODO: открыть список следующих треков (позже: showModalBottomSheet(...))
              },
              child: const Icon(
                Icons.menu,
                color: Color(0x66FFFFFF),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SVG-иконка снизу с поддержкой выделения.
class _BottomSvgIcon extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final double size;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;

  const _BottomSvgIcon({
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
