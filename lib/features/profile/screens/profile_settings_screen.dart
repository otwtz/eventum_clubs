import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/api_error_message.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  static void _showDeleteAccount(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.deleteAccountBody),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.deleteAccountPasswordHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final pwd = passwordCtrl.text.trim().isEmpty
                  ? null
                  : passwordCtrl.text.trim();
              Navigator.of(ctx).pop();
              try {
                await ref.read(authProvider.notifier).deleteAccount(
                      password: pwd,
                    );
                if (context.mounted) {
                  context.go('/login');
                }
              } on PlayGoApiException catch (e) {
                if (context.mounted) {
                  final l = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(friendlyApiError(e, l)),
                      backgroundColor: Colors.red.shade900,
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(context),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  final l = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.genericNetworkError),
                      backgroundColor: Colors.red.shade900,
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(context),
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.deleteAccountConfirm,
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    ).whenComplete(passwordCtrl.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0.8,
            child: SwitchListTile(
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.theme),
              subtitle: Text(
                themeMode == ThemeMode.dark
                    ? l10n.themeDark
                    : l10n.themeLight,
              ),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0.8,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                l10n.logout,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0.8,
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.deleteAccountTitle,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _showDeleteAccount(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
