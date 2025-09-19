import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TukaApp());
}

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
    textTheme:
    GoogleFonts.alumniSansTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
  );
}

/// Прямоугольный ползунок (квадрат задаётся размерами)
class RectThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;
  const RectThumbShape({this.thumbWidth = 6, this.thumbHeight = 18});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(thumbWidth, thumbHeight);

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

/// Кнопка-квадрат: темнеет при удержании + короткий флэш на быстрый тап
class PressableSquare extends StatefulWidget {
  final double size;
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double darkenAmount;
  final Duration releaseDuration;
  final Duration flashDuration;
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

class Track {
  final String title;
  final String artist;
  final String coverAsset;
  final String audioAsset;
  const Track({
    required this.title,
    required this.artist,
    required this.coverAsset,
    required this.audioAsset,
  });
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _player = AudioPlayer();

  final List<Track> tracks = const [
    Track(
      title: 'Double Цвет',
      artist: 'Tuka',
      coverAsset: 'assets/covers/draka.png',
      audioAsset: 'assets/audio/dablcvet_8.mp3',
    ),
    Track(
      title: 'Nota de Amor',
      artist: 'Tuka',
      coverAsset: 'assets/covers/nota.jpg',
      audioAsset: 'assets/audio/gala_10.mp3',
    ),
    Track(
      title: 'Улетим',
      artist: 'Tuka',
      coverAsset: 'assets/covers/fly.jpg',
      audioAsset: 'assets/audio/fly_3.mp3',
    ),
    Track(
      title: 'VVS',
      artist: 'Tuka',
      coverAsset: 'assets/covers/third.jpg',
      audioAsset: 'assets/audio/diamonds_9.mp3',
    ),
  ];

  ConcatenatingAudioSource? _playlist;

  bool liked = false;
  bool playing = false;

  double pos = 0;
  double total = 0;

  double? _dragPos;
  bool _isDragging = false;
  Timer? _seekDebounce;

  int bottomSelected = 0;

  Color dominant = AppTheme.bgTop;

  bool burgerPressed = false;

  bool _holdingPrev = false;
  bool _holdingNext = false;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _loadLike();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePaletteForIndex(_index);
  }

  Future<void> _initAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playlist = ConcatenatingAudioSource(
      children: [for (final t in tracks) AudioSource.asset(t.audioAsset)],
    );

    final initialDur = await _player.setAudioSource(_playlist!);
    if (mounted && initialDur != null) {
      setState(() => total = initialDur.inSeconds.toDouble());
    }

    // Автоповтор всего списка (круговой плейлист сам по себе)
    await _player.setLoopMode(LoopMode.all);

    _player.durationStream.listen((d) {
      if (!mounted) return;
      if (d == null) return;
      setState(() => total = d.inSeconds.toDouble());
    });

    _player.positionStream.listen((p) {
      if (!mounted || _isDragging) return;
      final secs = p.inSeconds.toDouble();
      setState(() => pos = total > 0 ? secs.clamp(0, total) : secs);
    });

    _player.playerStateStream.listen((st) {
      if (!mounted) return;
      final isDone = st.processingState == ProcessingState.completed;
      setState(() => playing = st.playing && !isDone);
    });

    _player.currentIndexStream.listen((i) async {
      if (!mounted || i == null) return;
      setState(() {
        _index = i;
        pos = 0;
        total = 0;
      });
      _updatePaletteForIndex(i);
      _loadLikeForIndex(i);
      _fixDurationForCurrent();
    });
  }

  Future<void> _fixDurationForCurrent() async {
    final d0 = _player.duration;
    if (mounted && d0 != null) {
      setState(() => total = d0.inSeconds.toDouble());
      return;
    }
    for (int tries = 0; tries < 8; tries++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final d = _player.duration;
      if (!mounted) return;
      if (d != null) {
        setState(() => total = d.inSeconds.toDouble());
        return;
      }
    }
  }

  // ===== likes =====
  Future<void> _loadLike() async => _loadLikeForIndex(_index);

  Future<void> _loadLikeForIndex(int i) async {
    final sp = await SharedPreferences.getInstance();
    setState(() => liked = sp.getBool('liked_${tracks[i].title}') ?? false);
  }

  Future<void> _saveLike(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('liked_${tracks[_index].title}', v);
  }

  // ===== playback =====
  Future<void> _togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _seekBy(Duration delta) {
    final now = _player.position + delta;
    final maxD = Duration(seconds: total.toInt());
    final target = now < Duration.zero ? Duration.zero : (now > maxD ? maxD : now);
    _player.seek(target);
  }

  // ЦИКЛИЧЕСКИЙ prev/next
  Future<void> _prevTrack() async {
    final i = _player.currentIndex;
    final count = tracks.length;
    if (i == null || count == 0) return;
    final prev = (i - 1 + count) % count;
    await _player.seek(Duration.zero, index: prev);
    await _player.play();
  }

  Future<void> _nextTrack() async {
    final i = _player.currentIndex;
    final count = tracks.length;
    if (i == null || count == 0) return;
    final next = (i + 1) % count;
    await _player.seek(Duration.zero, index: next);
    await _player.play();
  }

  // мелкая перемотка при удержании prev/next
  void _startHoldSeek({required bool forward}) async {
    if (forward) {
      _holdingNext = true;
    } else {
      _holdingPrev = true;
    }
    while ((forward && _holdingNext) || (!forward && _holdingPrev)) {
      _seekBy(Duration(seconds: forward ? 5 : -5));
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _stopHoldSeek() {
    _holdingNext = false;
    _holdingPrev = false;
  }

  // ===== slider debounced seek =====
  void _seekDebounced(Duration target) {
    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 250), () {
      _player.seek(target);
    });
  }

  // ===== visuals =====
  Future<void> _updatePaletteForIndex(int i) async {
    try {
      final cover = tracks[i].coverAsset;
      await precacheImage(AssetImage(cover), context);
      final palette = await PaletteGenerator.fromImageProvider(
        ResizeImage(AssetImage(cover), width: 200),
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
  void dispose() {
    _seekDebounce?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientTop = lighten(dominant, 0.15);
    final track = tracks[_index];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientTop, Colors.black],
                  stops: const [0.0, 0.8],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  // верх
                  Expanded(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      primary: false,
                      children: [
                        // поиск
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
                              prefixIcon: const Icon(Icons.search, color: Colors.white, size: 28),
                              filled: true,
                              fillColor: const Color.fromRGBO(20, 20, 20, 0.3),
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

                        // обложка с двойным тапом (±10с)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: FractionallySizedBox(
                            widthFactor: 0.9,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final boxW = constraints.maxWidth;
                                  return GestureDetector(
                                    onDoubleTapDown: (details) {
                                      final x = details.localPosition.dx;
                                      if (x < boxW / 2) {
                                        _seekBy(const Duration(seconds: -10));
                                      } else {
                                        _seekBy(const Duration(seconds: 10));
                                      }
                                    },
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
                                          track.coverAsset,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, st) => Container(
                                            color: Colors.white12,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Нет изображения',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // название / артист / лайк
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(20, -10),
                                    child: Text(track.title, style: AppTheme.title()),
                                  ),
                                  const SizedBox(height: 4),
                                  Transform.translate(
                                    offset: const Offset(22, -30),
                                    child: Text(track.artist, style: AppTheme.artist()),
                                  ),
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(-10, -20),
                              child: IconButton(
                                iconSize: 36,
                                onPressed: () async {
                                  final v = !liked;
                                  setState(() => liked = v);
                                  await _saveLike(v);
                                },
                                icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                                color: liked ? AppTheme.accent : AppTheme.textPri,
                              ),
                            ),
                          ],
                        ),

                        // таймлайн + кнопки
                        SizedBox(
                          height: 210,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // слайдер + тайминги
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
                                            value: ((_dragPos ?? pos).isFinite
                                                ? (_dragPos ?? pos)
                                                : 0.0)
                                                .clamp(0.0, total > 0 ? total : 1.0),
                                            min: 0,
                                            max: total > 0 ? total : 1,
                                            onChangeStart: (_) {
                                              _isDragging = true;
                                              _dragPos = pos;
                                              setState(() {});
                                            },
                                            onChanged: total > 0
                                                ? (v) {
                                              final clamped = v.clamp(0.0, total);
                                              setState(() => _dragPos = clamped);
                                              _seekDebounced(
                                                  Duration(seconds: clamped.round()));
                                            }
                                                : null,
                                            onChangeEnd: (v) {
                                              _seekDebounce?.cancel();
                                              final clamped = v.clamp(0.0, total);
                                              _player.seek(Duration(seconds: clamped.round()));
                                              _dragPos = null;
                                              _isDragging = false;
                                            },
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

                              // кнопки управления — подняты
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // PREV (удержание — мелкая перемотка)
                                    GestureDetector(
                                      onLongPressStart: (_) => _startHoldSeek(forward: false),
                                      onLongPressEnd: (_) => _stopHoldSeek(),
                                      child: PressableSquare(
                                        size: 55,
                                        onTap: _prevTrack,
                                        child: const Icon(Icons.skip_previous,
                                            color: Colors.black, size: 55),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // PLAY/PAUSE
                                    PressableSquare(
                                      size: 75,
                                      onTap: _togglePlay,
                                      child: Icon(
                                        playing ? Icons.pause : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 72,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // NEXT (удержание — мелкая перемотка)
                                    GestureDetector(
                                      onLongPressStart: (_) => _startHoldSeek(forward: true),
                                      onLongPressEnd: (_) => _stopHoldSeek(),
                                      child: PressableSquare(
                                        size: 55,
                                        onTap: _nextTrack,
                                        child: const Icon(Icons.skip_next,
                                            color: Colors.black, size: 55),
                                      ),
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

                  // нижний ряд (SVG)
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

          // бургер
          Positioned(
            right: 24,
            bottom: 105,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => burgerPressed = true),
              onTapUp: (_) => setState(() => burgerPressed = false),
              onTapCancel: () => setState(() => burgerPressed = false),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: burgerPressed ? 1 : 0),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => Icon(
                      Icons.menu,
                      color: Color.lerp(const Color(0x66FFFFFF), Colors.white, t)!,
                      size: 32,
                    ),
                  ),
                ),
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
