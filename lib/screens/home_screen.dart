import 'package:flutter/material.dart';
import '../models/track.dart';
import '../theme.dart';
import 'player_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_svg_icon.dart ';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Страница поиска', style: TextStyle(color: Colors.white)),
    );
  }
}

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Страница загрузки треков', style: TextStyle(color: Colors.white)),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Страница сообщений', style: TextStyle(color: Colors.white)),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int bottomSelected = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ====== IndexedStack вместо switch ======
          Positioned.fill(
            child: IndexedStack(
              index: bottomSelected,
              children: [
                PlayerScreen(tracks: tracks),          // Главная
                const SearchScreen(),                  // Поиск
                const UploadScreen(),                  // Загрузка
                const MessagesScreen(),                // Сообщения
                ProfileScreen(allTracks: tracks),      // Профиль
              ],
            ),
          ),

          // ====== Нижняя навигация ======
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BottomSvgIcon(
                      asset: 'assets/icons/home_icon.svg',
                      selected: bottomSelected == 0,
                      onTap: () => setState(() => bottomSelected = 0),
                    ),
                    BottomSvgIcon(
                      asset: 'assets/icons/search_icon.svg',
                      selected: bottomSelected == 1,
                      onTap: () => setState(() => bottomSelected = 1),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => bottomSelected = 2),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.white,
                        child: const Center(
                          child: Icon(Icons.add, color: Colors.black, size: 36),
                        ),
                      ),
                    ),
                    BottomSvgIcon(
                      asset: 'assets/icons/messages_icon.svg',
                      selected: bottomSelected == 3,
                      onTap: () => setState(() => bottomSelected = 3),
                    ),
                    BottomSvgIcon(
                      asset: 'assets/icons/profile_icon.svg',
                      selected: bottomSelected == 4,
                      onTap: () => setState(() => bottomSelected = 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
