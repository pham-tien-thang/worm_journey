import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../settings/settings.dart';
import '../style/palette.dart';

/// App: MainMenuScreen → /play (chọn level) → /play/game/:level (game).
class WormJourneyApp extends StatelessWidget {
  const WormJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          Provider(create: (context) => SettingsController()),
          Provider(create: (context) => Palette()),
          ProxyProvider2<
              AppLifecycleStateNotifier, SettingsController, AudioController>(
            create: (context) => AudioController(),
            update: (context, lifecycleNotifier, settings, audio) {
              audio!.attachDependencies(lifecycleNotifier, settings);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
            lazy: false,
          ),
        ],
        child: Builder(
          builder: (context) {
            final palette = context.watch<Palette>();
            return MaterialApp.router(
              title: 'Worm Journey',
              debugShowCheckedModeBanner: false,
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: palette.darkPen,
                  surface: palette.backgroundMain,
                ),
                textTheme: TextTheme(
                  bodyMedium: TextStyle(color: palette.ink),
                ),
                useMaterial3: true,
              ).copyWith(
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              routerConfig: createAppRouter(),
            );
          },
        ),
      ),
    );
  }
}
