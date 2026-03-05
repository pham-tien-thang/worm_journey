import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../gen_l10n/app_localizations.dart';

/// Màn chọn level: nền full, 3 ô Lv1/Lv2/Lv3, nút Back.
class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  static const int _levelCount = 3;

  @override
  Widget build(BuildContext context) {
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
                IconButton(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 96 + 16,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      for (int level = 1; level <= _levelCount; level++) ...[
                        if (level > 1) const SizedBox(width: 24),
                        _LevelBox(
                          level: level,
                          onTap: () =>
                              context.push(AppRoutes.game(level)),
                        ),
                      ],
                    ],
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
              AppLocalizations.of(context).levelLabel(level),
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
