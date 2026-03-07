import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../inject/injection.dart';
import '../../widgets/green_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n;
    return Scaffold(
      backgroundColor: const Color(0xFF1B3D2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/main_menu_bg_2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Image.asset(
                    'assets/images/worm_journey_logo.png',
                    fit: BoxFit.contain,
                    width: 280,
                  ),
                  const SizedBox(height: 200),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GreenButton(
                      text: l10n.buttonJourney,
                      onPressed: () => context.push(AppRoutes.play),
                      width: 175,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GreenButton(
                      text: l10n.buttonChallenge,
                      onPressed: () => context.push(AppRoutes.challenge),
                      width: 175,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GreenButton(
                      text: l10n.buttonShop,
                      onPressed: () => context.push(AppRoutes.shop),
                      width: 175,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GreenButton(
                      text: l10n.buttonSettings,
                      onPressed: () => context.push(AppRoutes.settings),
                      width: 175,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
