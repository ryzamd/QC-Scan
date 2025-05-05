import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_colors.dart';
import '../localization/language_bloc.dart';

class LanguageSelector extends StatelessWidget {
  final bool showLabel;
  final Color? iconColor;
  
  const LanguageSelector({
    super.key,
    this.showLabel = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final locale = state.locale;
        
        Widget flagIcon;
        if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
           flagIcon = Image.asset('assets/flags/TW.png', width: 28, height: 28);
        } else if (locale.languageCode == 'zh' && locale.countryCode == 'CN') {
          flagIcon = Image.asset('assets/flags/CN.png', width: 28, height: 28);
        } else {
          flagIcon = Image.asset('assets/flags/US.png', width: 28, height: 28);
        }
        
        return PopupMenuButton<LanguageEvent>(
          onSelected: (event) {
            context.read<LanguageBloc>().add(event);
          },
          offset: const Offset(0, 10),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              flagIcon,
              if (showLabel) ...[
                const SizedBox(width: 8),
                const Text('Language', style: TextStyle(color: Colors.white)),
              ],
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: LanguageEvent.toChineseTraditional,
              child: Row(
                children: [
                  Image.asset('assets/flags/TW.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  const Text('繁體中文'),
                  const Spacer(),
                  if (locale.languageCode == 'zh' && locale.countryCode == 'TW')
                    Icon(Icons.check, color: iconColor ?? AppColors.primary),
                ],
              ),
            ),
            PopupMenuItem(
              value: LanguageEvent.toChineseSimplified,
              child: Row(
                children: [
                  Image.asset('assets/flags/CN.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  const Text('简体中文'),
                  const Spacer(),
                  if (locale.languageCode == 'zh' && locale.countryCode == 'CN')
                    Icon(Icons.check, color: iconColor ?? AppColors.primary),
                ],
              ),
            ),
            PopupMenuItem(
              value: LanguageEvent.toEnglish,
              child: Row(
                children: [
                  Image.asset('assets/flags/US.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  const Text('English'),
                  const Spacer(),
                  if (locale.languageCode == 'en')
                    Icon(Icons.check, color: iconColor ?? AppColors.primary),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}