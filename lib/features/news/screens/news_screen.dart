import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/shell_nav_bar_spacer.dart';

/// Вкладка «Новости» (контент с API можно подключить позже).
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.news),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        children: [
          Text(
            l10n.newsPlaceholder,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const ShellNavBarSpacer(),
        ],
      ),
    );
  }
}
