import 'package:flutter/material.dart';

void main() {
  runApp(const MemoriesApp());
}

class MemoriesApp extends StatelessWidget {
  const MemoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Memories',
      home: Scaffold(
        body: Center(
          child: Text('Memories App'),
        ),
      ),
    );
  }
}
