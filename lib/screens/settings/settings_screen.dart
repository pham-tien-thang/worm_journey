import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/services/shared_prefs_service.dart';
import '../../gen_l10n/app_localizations.dart';

/// Màn cài đặt: đổi ngôn ngữ và bật/tắt âm thanh, lưu qua SharedPreferences.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Set<String> _supportedLanguageCodes = {'en', 'vi'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.hudTextBrown,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.hudBackground,
                          side: const BorderSide(
                            color: AppColors.hudBorder,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.settingsTitle,
                        style: const TextStyle(
                          color: AppColors.hudBackground,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: AppColors.hudTextBrown,
                              offset: Offset(1, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 24,
                        ),
                        child: AnimatedBuilder(
                          animation: appSettingsNotifier,
                          builder: (context, _) {
                            final platformLanguageCode =
                                Localizations.localeOf(context).languageCode;
                            final selectedLanguageCode =
                                appSettingsNotifier.languageCode ??
                                (_supportedLanguageCodes.contains(
                                      platformLanguageCode,
                                    )
                                    ? platformLanguageCode
                                    : 'en');

                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.hudBackground.withValues(
                                  alpha: 0.96,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.hudBorder,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 8),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _SettingsTile(
                                      icon: Icons.language,
                                      title: l10n.settingsLanguage,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _ChoicePill(
                                              text: l10n.settingsEnglish,
                                              selected:
                                                  selectedLanguageCode == 'en',
                                              onTap:
                                                  () => appSettingsNotifier
                                                      .setLanguageCode('en'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _ChoicePill(
                                              text: l10n.settingsVietnamese,
                                              selected:
                                                  selectedLanguageCode == 'vi',
                                              onTap:
                                                  () => appSettingsNotifier
                                                      .setLanguageCode('vi'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 28,
                                      color: AppColors.hudBorder,
                                    ),
                                    _SettingsTile(
                                      icon:
                                          appSettingsNotifier.soundEnabled
                                              ? Icons.volume_up
                                              : Icons.volume_off,
                                      title: l10n.settingsSound,
                                      child: Row(
                                        children: [
                                          Text(
                                            appSettingsNotifier.soundEnabled
                                                ? l10n.settingsSoundOn
                                                : l10n.settingsSoundOff,
                                            style: const TextStyle(
                                              color: AppColors.hudTextBrown,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const Spacer(),
                                          Switch(
                                            value:
                                                appSettingsNotifier
                                                    .soundEnabled,
                                            onChanged:
                                                appSettingsNotifier
                                                    .setSoundEnabled,
                                            activeThumbColor: const Color(
                                              0xFF9DE45A,
                                            ),
                                            activeTrackColor: const Color(
                                              0xFF2E7D32,
                                            ),
                                            inactiveThumbColor:
                                                AppColors.hudTextBrown,
                                            inactiveTrackColor: const Color(
                                              0xFFD8BE91,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 28,
                                      color: AppColors.hudBorder,
                                    ),
                                    _SettingsTile(
                                      icon:
                                          appSettingsNotifier.hapticsEnabled
                                              ? Icons.vibration
                                              : Icons.phonelink_erase,
                                      title: l10n.settingsHaptics,
                                      child: Row(
                                        children: [
                                          Text(
                                            appSettingsNotifier.hapticsEnabled
                                                ? l10n.settingsHapticsOn
                                                : l10n.settingsHapticsOff,
                                            style: const TextStyle(
                                              color: AppColors.hudTextBrown,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const Spacer(),
                                          Switch(
                                            value:
                                                appSettingsNotifier
                                                    .hapticsEnabled,
                                            onChanged:
                                                appSettingsNotifier
                                                    .setHapticsEnabled,
                                            activeThumbColor: const Color(
                                              0xFF9DE45A,
                                            ),
                                            activeTrackColor: const Color(
                                              0xFF2E7D32,
                                            ),
                                            inactiveThumbColor:
                                                AppColors.hudTextBrown,
                                            inactiveTrackColor: const Color(
                                              0xFFD8BE91,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.hudTextBrown, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.hudTextBrown,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFD8BE91),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.hudTextBrown : AppColors.hudBorder,
              width: 2,
            ),
            boxShadow:
                selected
                    ? const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ]
                    : null,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.hudTextBrown,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows:
                  selected
                      ? const [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 1,
                        ),
                      ]
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
