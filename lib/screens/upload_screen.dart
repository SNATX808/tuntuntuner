import 'package:flutter/material.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выложить трек'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Здесь будет форма для загрузки трека',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
