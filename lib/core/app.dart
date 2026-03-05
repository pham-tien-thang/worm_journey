import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../gen_l10n/app_localizations.dart';

class WormJourneyApp extends StatefulWidget {
  const WormJourneyApp({super.key});

  @override
  State<WormJourneyApp> createState() => _WormJourneyAppState();
}

class _WormJourneyAppState extends State<WormJourneyApp> {
  Locale? _locale;
  late final GoRouter _router = createAppRouter();
  bool _didPrecacheImages = false;

  static Locale _resolveLocale(Locale? locale, Iterable<Locale> supported) {
    if (locale == null) return supported.first;
    for (final s in supported) {
      if (s.languageCode == locale.languageCode) return s;
    }
    return const Locale('en');
  }

  /// Lấy locale theo danh sách ưu tiên của thiết bị.
  static Locale _deviceResolvedLocale() {
    final preferred = PlatformDispatcher.instance.locales;
    final supported = AppLocalizations.supportedLocales;
    for (final locale in preferred) {
      final resolved = _resolveLocale(locale, supported);
      if (resolved.languageCode == locale.languageCode) return resolved;
    }
    return const Locale('en');
  }

  @override
  void initState() {
    super.initState();
    _locale = _deviceResolvedLocale();
    // Build đầu có thể chạy khi platform chưa báo đủ locales; build lại sau frame đầu để lấy đúng locale thiết bị (tránh màn main tiếng Anh trong khi màn trong tiếng Việt).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resolved = _deviceResolvedLocale();
      if (mounted && resolved != _locale) {
        setState(() => _locale = resolved);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_didPrecacheImages) {
      _didPrecacheImages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          precacheImage(
            const AssetImage('assets/images/select_level.png'),
            context,
          );
        }
      });
    }
    final resolvedLocale = _locale ?? _deviceResolvedLocale();
    return MaterialApp.router(
      title: 'Worm Journey',
      locale: resolvedLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
