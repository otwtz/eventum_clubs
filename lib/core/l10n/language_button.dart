import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import 'app_localizations.dart';

/// Кнопка смены языка: по нажатию переключает язык (RU ↔ EN).
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isRu = currentLocale?.languageCode == 'ru';
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: Text(
        isRu ? 'EN' : 'RU',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      tooltip: l10n != null
          ? '${l10n.language}: ${isRu ? l10n.english : l10n.russian}'
          : (isRu ? 'Language: English' : 'Language: Russian'),
      onPressed: () {
        ref.read(localeProvider.notifier).setLocale(
              isRu ? const Locale('en') : const Locale('ru'),
            );
      },
    );
  }
}
