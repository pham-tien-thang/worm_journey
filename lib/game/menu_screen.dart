import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../widgets/back_image_button.dart';

/// Màn chọn level: nền full, SafeArea cho nội dung, nút Back (ảnh), 3 ô level hàng ngang ở đầu màn.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const int _levelCount = 3;

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/select_level.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackImageButton(
                  onPressed: () {
                    audioController.playSfx(SfxType.buttonTap);
                    context.go('/');
                  },
                  size: 48,
                  padding: const EdgeInsets.only(left: 8, top: 8),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 96 + 16,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        for (int level = 1; level <= _levelCount; level++) ...[
                          if (level > 1) const SizedBox(width: 24),
                          _LevelBox(
                            level: level,
                            onTap: () {
                              audioController.playSfx(SfxType.buttonTap);
                              context.go('/play/game/$level');
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô vuông viền trắng, bo góc, nền xanh lá, text Lv1/Lv2/Lv3.
class _LevelBox extends StatelessWidget {
  const _LevelBox({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: Center(
            child: Text(
              'Lv$level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
