// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../settings/settings.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/main_menu_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ResponsiveScreen(
            squarishMainArea: Center(
              child: Image.asset(
                'assets/images/worm_journey_logo.png',
                fit: BoxFit.contain,
                width: 280,
              ),
            ),
            rectangularMenuArea: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(
                  backgroundColor: const Color(0xFF1B5E20),
                  borderColor: Colors.white,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    audioController.playSfx(SfxType.buttonTap);
                    GoRouter.of(context).go('/play');
                  },
                  child: const Text('Play'),
                ),
                _gap,

                _gap,
                _gap,
                _gap,
                _gap,
                _gap,
                _gap,
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: settingsController.audioOn,
                    builder: (context, audioOn, child) {
                      return IconTheme(
                        data: const IconThemeData(color: Colors.white),
                        child: IconButton(
                          onPressed: settingsController.toggleAudioOn,
                          icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off),
                        ),
                      );
                    },
                  ),
                ),
                _gap,
                Text(
                  'Music by Mr Smith',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: _whiteWithOrangeOutlineShadows,
                  ),
                ),
                _gap,
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _gap = SizedBox(height: 10);

  static const List<Shadow> _whiteWithOrangeOutlineShadows = [
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(-1, -1)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(1, -1)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(-1, 1)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(1, 1)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(0, -1)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(0, 1)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(-1, 0)),
    Shadow(blurRadius: 0, color: Colors.orange, offset: Offset(1, 0)),
  ];
}
