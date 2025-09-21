import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme.dart';
import '../models/track.dart';
import '../widgets/pressable_square.dart';
import '../widgets/rect_slider.dart';
import '../widgets/bottom_svg_icon.dart';

class PlayerScreen extends StatefulWidget {
  final List<Track> tracks; // теперь можно передавать треки

  const PlayerScreen({super.key, required this.tracks});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final List<Track> tracks;
  final AudioPlayer _player = AudioPlayer();

  ConcatenatingAudioSource? _playlist;
  bool liked = false;
  bool playing = false;
  double pos = 0;
  double total = 0;
  double? _dragPos;
  bool _isDragging = false;
  Timer? _seekDebounce;
  int _index = 0;
  bool _holdingPrev = false;
  bool _holdingNext = false;
  Color dominant = AppTheme.bgTop;
  bool burgerPressed = false;

  @override
  void initState() {
    super.initState();
    tracks = widget.tracks; // берём треки из конструктора
    _initAudio();
    _loadLike();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePaletteForIndex(_index);
  }

  // ===================== AUDIO =====================
  Future<void> _initAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playlist = ConcatenatingAudioSource(
      children: [for (final t in tracks) AudioSource.asset(t.audioAsset)],
    );

    final initialDur = await _player.setAudioSource(_playlist!);
    if (mounted && initialDur != null)
      setState(() => total = initialDur.inSeconds.toDouble());

    await _player.setLoopMode(LoopMode.all);

    _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
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

  // ===================== LIKES =====================
  Future<void> _loadLike() async => _loadLikeForIndex(_index);

  Future<void> _loadLikeForIndex(int i) async {
    final sp = await SharedPreferences.getInstance();
    setState(() => liked = sp.getBool('liked_${tracks[i].title}') ?? false);
  }

  Future<void> _saveLike(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('liked_${tracks[_index].title}', v);
  }

  // ===================== PLAYBACK =====================
  Future<void> _togglePlay() async {
    if (_player.playing)
      await _player.pause();
    else
      await _player.play();
  }

  void _seekBy(Duration delta) {
    final now = _player.position + delta;
    final maxD = Duration(seconds: total.toInt());
    final target = now < Duration.zero
        ? Duration.zero
        : (now > maxD ? maxD : now);
    _player.seek(target);
  }

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

  void _startHoldSeek({required bool forward}) async {
    if (forward)
      _holdingNext = true;
    else
      _holdingPrev = true;

    while ((forward && _holdingNext) || (!forward && _holdingPrev)) {
      _seekBy(Duration(seconds: forward ? 5 : -5));
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _stopHoldSeek() {
    _holdingNext = false;
    _holdingPrev = false;
  }

  void _seekDebounced(Duration target) {
    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 250), () {
      _player.seek(target);
    });
  }

  // ===================== VISUALS =====================
  Future<void> _updatePaletteForIndex(int i) async {
    try {
      final cover = tracks[i].coverAsset;
      await precacheImage(AssetImage(cover), context);
      final palette = await PaletteGenerator.fromImageProvider(
        ResizeImage(AssetImage(cover), width: 200),
        maximumColorCount: 20,
      );

      final color =
          palette.dominantColor?.color ??
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
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
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
      resizeToAvoidBottomInset: false,
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
                  // ======== MAIN PLAYER UI ========
                  Expanded(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      primary: false,
                      children: [
                        // --- Search ---
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
                                color: Colors.white54,
                                fontSize: 24,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 28,
                              ),
                              filled: true,
                              fillColor: const Color.fromRGBO(20, 20, 20, 0.3),
                              contentPadding: const EdgeInsets.symmetric(
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
                        // --- Cover Art ---
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
                                      if (x < boxW / 2)
                                        _seekBy(const Duration(seconds: -10));
                                      else
                                        _seekBy(const Duration(seconds: 10));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
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
                                          errorBuilder: (ctx, err, st) =>
                                              Container(
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

                        // Название / артист / лайк
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(20, -10),
                                    child: Text(
                                      track.title,
                                      style: AppTheme.title(),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Transform.translate(
                                    offset: const Offset(22, -30),
                                    child: Text(
                                      track.artist,
                                      style: AppTheme.artist(),
                                    ),
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
                                icon: Icon(
                                  liked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                color: liked
                                    ? Colors.red
                                    : AppTheme.textPri,
                              ),
                            ),
                          ],
                        ),

                        // Таймлайн + кнопки управления
                        SizedBox(
                          height: 210,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Слайдер + тайминги
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
                                            trackShape:
                                                const RectSliderTrackShape(),
                                            activeTrackColor: Colors.white,
                                            inactiveTrackColor: Colors.white54,
                                            thumbColor: Colors.white,
                                            thumbShape: const RectThumbShape(
                                              thumbWidth: 14,
                                              thumbHeight: 14,
                                            ),
                                            overlayShape:
                                                SliderComponentShape.noOverlay,
                                          ),
                                          child: Slider(
                                            value:
                                                ((_dragPos ?? pos).isFinite
                                                        ? (_dragPos ?? pos)
                                                        : 0.0)
                                                    .clamp(
                                                      0.0,
                                                      total > 0 ? total : 1.0,
                                                    ),
                                            min: 0,
                                            max: total > 0 ? total : 1,
                                            onChangeStart: (_) {
                                              _isDragging = true;
                                              _dragPos = pos;
                                              setState(() {});
                                            },
                                            onChanged: total > 0
                                                ? (v) {
                                                    final clamped = v.clamp(
                                                      0.0,
                                                      total,
                                                    );
                                                    setState(
                                                      () => _dragPos = clamped,
                                                    );
                                                    _seekDebounced(
                                                      Duration(
                                                        seconds: clamped
                                                            .round(),
                                                      ),
                                                    );
                                                  }
                                                : null,
                                            onChangeEnd: (v) {
                                              _seekDebounce?.cancel();
                                              final clamped = v.clamp(
                                                0.0,
                                                total,
                                              );
                                              _player.seek(
                                                Duration(
                                                  seconds: clamped.round(),
                                                ),
                                              );
                                              _dragPos = null;
                                              _isDragging = false;
                                            },
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: 0.9,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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

                              // Кнопки управления
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onLongPressStart: (_) =>
                                          _startHoldSeek(forward: false),
                                      onLongPressEnd: (_) => _stopHoldSeek(),
                                      child: PressableSquare(
                                        size: 55,
                                        onTap: _prevTrack,
                                        child: const Icon(
                                          Icons.skip_previous,
                                          color: Colors.black,
                                          size: 55,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    PressableSquare(
                                      size: 75,
                                      onTap: _togglePlay,
                                      child: Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 72,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    GestureDetector(
                                      onLongPressStart: (_) =>
                                          _startHoldSeek(forward: true),
                                      onLongPressEnd: (_) => _stopHoldSeek(),
                                      child: PressableSquare(
                                        size: 55,
                                        onTap: _nextTrack,
                                        child: const Icon(
                                          Icons.skip_next,
                                          color: Colors.black,
                                          size: 55,
                                        ),
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
                ],
              ),
            ),
          ),

          // Бургер-кнопка
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
                      color: Color.lerp(
                        const Color(0x66FFFFFF),
                        Colors.white,
                        t,
                      )!,
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
