import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'models/track.dart';

class AudioManager {
  // Singleton
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;

  // Список треков
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

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _playlist = ConcatenatingAudioSource(
      children: [for (var t in tracks) AudioSource.asset(t.audioAsset)],
    );

    await player.setAudioSource(_playlist!);
    await player.setLoopMode(LoopMode.all);

    _initialized = true;
  }

  // Переключение на конкретный трек
  Future<void> playTrack(int index) async {
    await init();
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> nextTrack() async {
    final i = player.currentIndex;
    if (i == null) return;
    final next = (i + 1) % tracks.length;
    await playTrack(next);
  }

  Future<void> prevTrack() async {
    final i = player.currentIndex;
    if (i == null) return;
    final prev = (i - 1 + tracks.length) % tracks.length;
    await playTrack(prev);
  }

  void dispose() {
    player.dispose();
  }
}
