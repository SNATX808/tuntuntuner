import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  final List<Track> allTracks;

  const ProfileScreen({super.key, required this.allTracks});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Track> likedTracks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedTracks();
  }

  Future<void> _loadLikedTracks() async {
    setState(() => loading = true);
    final sp = await SharedPreferences.getInstance();
    final likes = widget.allTracks
        .where((t) => sp.getBool('liked_${t.title}') ?? false)
        .toList();
    setState(() {
      likedTracks = likes;
      loading = false;
    });
  }

  Future<void> _toggleLike(Track track) async {
    final sp = await SharedPreferences.getInstance();
    final key = 'liked_${track.title}';
    final now = sp.getBool(key) ?? false;
    await sp.setBool(key, !now);

    setState(() {
      if (!now) {
        likedTracks.add(track);
      } else {
        likedTracks.removeWhere((t) => t.title == track.title);
      }
    });
  }

  Widget _buildHeader() {
    final initials = widget.allTracks.isNotEmpty
        ? (widget.allTracks.first.artist.isNotEmpty ? widget.allTracks.first.artist[0] : 'U')
        : 'U';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white12,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Профиль', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${likedTracks.length} лайков', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF0000),
        title: const Text('Профиль', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF0000), Colors.black],
            stops: [0.0, 0.8],
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadLikedTracks,
          child: likedTracks.isEmpty
              ? ListView(
            children: [
              _buildHeader(),
              const SizedBox(height: 80),
              const Center(
                child: Text(
                  'Нет лайкнутых треков',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                  child: const Text('Вернуться к трекам', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          )
              : ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: likedTracks.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10), // расстояние между треками фиксированное
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeader(); // первый элемент — шапка
              final track = likedTracks[index - 1];

              return Container(
                height: 64, // фиксированная высота трека
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // обложка с тенью
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            offset: Offset(0, 0),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          track.coverAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white12,
                            child: const Icon(Icons.music_note, color: Colors.white30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // текст с независимым позиционированием через Transform
                    Expanded(
                      child: Stack(
                        children: [
                          // Название трека
                          Transform.translate(
                            offset: const Offset(5, -12), // двигаешь вверх/вниз
                            child: Text(
                              track.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                          ),
                          // Артист
                          Transform.translate(
                            offset: const Offset(5, 18), // двигаешь вверх/вниз
                            child: Text(
                              track.artist,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleLike(track),
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
