import 'package:flutter/material.dart';

import 'game_screen.dart';

/// Màn menu: chọn level (LV 1, LV 2, LV 3) rồi vào game.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Worm Journey',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              _LevelButton(level: 1),
              const SizedBox(height: 16),
              _LevelButton(level: 2),
              const SizedBox(height: 16),
              _LevelButton(level: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => GameScreen(level: level),
          ),
        );
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      child: Text('LV $level'),
    );
  }
}
