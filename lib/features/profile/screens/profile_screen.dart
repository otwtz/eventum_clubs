import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/play_go_api_client.dart';
import '../../../../core/constants/shell_layout.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/api_error_message.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/team_input_utils.dart';
import '../../../../core/l10n/language_button.dart';
import '../../../../core/widgets/shell_nav_bar_spacer.dart';
import '../../../../models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _contactsExpanded = false;

  Future<void> _refreshProfile() async {
    await ref.read(authProvider.notifier).refreshSessionUser();
  }

  static Future<T?> _showBlurOverlayDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, _, _) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: 24 + ShellLayout.floatingNavClearancePadding(ctx),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: builder(ctx),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    );
  }

  static Widget _overlayDialogCard({
    required BuildContext context,
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge ??
                    const TextStyle(fontSize: 22),
                child: title,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(child: content),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .expand((w) => [w, const SizedBox(width: 8)])
                    .toList()
                  ..removeLast(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _overlayFieldDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: fillColor,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: authState.isAuthenticated && authState.user != null
          ? AppBar(
              title: Text(l10n?.profile ?? 'Профиль'),
              leading: const LanguageButton(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: l10n?.settings ?? 'Настройки',
                  onPressed: () => context.push('/profile/settings'),
                ),
              ],
            )
          : null,
      body: authState.isAuthenticated && authState.user != null
          ? RefreshIndicator(
              onRefresh: _refreshProfile,
              child: _buildAuthenticatedProfile(
                context,
                ref,
                authState.user!,
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  static void _showEditProfile(BuildContext context, WidgetRef ref, UserModel user) {
    final emailCtrl = TextEditingController(text: user.email);
    final usernameCtrl = TextEditingController(text: user.username);
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final lastNameCtrl = TextEditingController(text: user.lastName);
    final cityCtrl = TextEditingController(text: user.city);

    _showBlurOverlayDialog(
      context: context,
      builder: (ctx) {
        final ctxL10n = AppLocalizations.of(ctx)!;
        return _overlayDialogCard(
          context: ctx,
          title: Text(ctxL10n.editProfile),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.email,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.nickname,
                  hintText: ctxL10n.nickname,
                ),
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: firstNameCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.firstName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.lastName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.city,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctxL10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final username = usernameCtrl.text.trim();
                final firstName = firstNameCtrl.text.trim();
                final lastName = lastNameCtrl.text.trim();
                final city = cityCtrl.text.trim();
                if (email.isEmpty ||
                    username.isEmpty ||
                    firstName.isEmpty ||
                    lastName.isEmpty ||
                    city.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ctxL10n.fillAllFields),
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(ctx),
                    ),
                  );
                  return;
                }
                if (!TeamInputUtils.isValidUsername(username)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ctxL10n.inviteInvalidLoginOrEmail),
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(ctx),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await ref.read(authProvider.notifier).updateProfile(
                        email: email,
                        username: username,
                        firstName: firstName,
                        lastName: lastName,
                        city: city,
                      );
                  if (ctx.mounted) {
                    final cL10n = AppLocalizations.of(ctx)!;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(cL10n.profileUpdated),
                        behavior: SnackBarBehavior.floating,
                        margin: ShellLayout.snackBarMargin(ctx),
                      ),
                    );
                  }
                } on PlayGoApiException catch (e) {
                  if (ctx.mounted) {
                    final l = AppLocalizations.of(ctx)!;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(friendlyApiError(e, l)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: ShellLayout.snackBarMargin(ctx),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    final l = AppLocalizations.of(ctx)!;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(friendlyApiError(e, l)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: ShellLayout.snackBarMargin(ctx),
                      ),
                    );
                  }
                }
              },
              child: Text(ctxL10n.save),
            ),
          ],
        );
      },
    );
  }

  static void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    _showBlurOverlayDialog(
      context: context,
      builder: (ctx) {
        final ctxL10n = AppLocalizations.of(ctx)!;
        return _overlayDialogCard(
          context: ctx,
          title: Text(ctxL10n.changePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.currentPassword,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.newPassword,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                decoration: _overlayFieldDecoration(
                  ctx,
                  labelText: ctxL10n.repeatPassword,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctxL10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final current = currentCtrl.text;
                final newP = newCtrl.text;
                final confirm = confirmCtrl.text;
                if (current.isEmpty || newP.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ctxL10n.fillPassword),
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(ctx),
                    ),
                  );
                  return;
                }
                if (newP.length < 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ctxL10n.passwordMin6),
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(ctx),
                    ),
                  );
                  return;
                }
                if (newP != confirm) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ctxL10n.passwordsDontMatch),
                      behavior: SnackBarBehavior.floating,
                      margin: ShellLayout.snackBarMargin(ctx),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await ref.read(authProvider.notifier).changePassword(
                        oldPassword: current,
                        newPassword: newP,
                      );
                  if (ctx.mounted) {
                    final cL10n = AppLocalizations.of(ctx)!;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(cL10n.passwordChanged),
                        behavior: SnackBarBehavior.floating,
                        margin: ShellLayout.snackBarMargin(ctx),
                      ),
                    );
                  }
                } on PlayGoApiException catch (e) {
                  if (ctx.mounted) {
                    final l = AppLocalizations.of(ctx)!;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(friendlyApiError(e, l)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: ShellLayout.snackBarMargin(ctx),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    final l = AppLocalizations.of(ctx)!;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(friendlyApiError(e, l)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: ShellLayout.snackBarMargin(ctx),
                      ),
                    );
                  }
                }
              },
              child: Text(ctxL10n.change),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthenticatedProfile(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Фото слева, ник / имя / фамилия справа
        Card(
          elevation: 0.8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: _buildProfileImage(user.photoPath, context),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.username.startsWith('@')
                                ? user.username.substring(1)
                                : user.username,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (user.isBlocked) ...[
                            const SizedBox(height: 8),
                            Chip(
                              avatar: Icon(
                                Icons.block,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              label: Text(l10n.blockedUserBadge),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _contactsExpanded = !_contactsExpanded;
                        });
                      },
                      icon: AnimatedRotation(
                        turns: _contactsExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      tooltip: l10n.contactInfo,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.contactInfo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProfileItem(l10n.email, user.email),
                        const SizedBox(height: 8),
                        _buildProfileItem(l10n.city, user.city),
                      ],
                    ),
                  ),
                  crossFadeState: _contactsExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 240),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showEditProfile(context, ref, user),
                        style: ElevatedButton.styleFrom(
                          elevation: 3,
                          shadowColor: Colors.black38,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showChangePassword(context, ref),
                        style: ElevatedButton.styleFrom(
                          elevation: 3,
                          shadowColor: Colors.black38,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0.8,
          child: ListTile(
            leading: Icon(
              Icons.psychology_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.smartMatchTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/ai-coaches'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0.8,
          child: ListTile(
            leading: Icon(
              Icons.star_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.myClubsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/my-clubs'),
          ),
        ),
        const ShellNavBarSpacer(),
      ],
    );
  }

  static const TextStyle _profileFieldLabelStyle = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );

  /// Подпись с «:» в одной строке, значение строкой ниже.
  Widget _buildProfileItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: _profileFieldLabelStyle,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildProfileImage(String? photoPath, BuildContext context) {
    if (photoPath == null || photoPath.isEmpty) {
      return Icon(
        Icons.person,
        size: 50,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    if (kIsWeb) {
      // Для веб-платформы используем NetworkImage или AssetImage
      return ClipOval(
        child: Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            );
          },
        ),
      );
    } else {
      // Для нативных платформ используем File
      try {
        final file = File(photoPath);
        if (file.existsSync()) {
          return ClipOval(
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
          );
        } else {
          return Icon(
            Icons.person,
            size: 50,
            color: Theme.of(context).colorScheme.primary,
          );
        }
      } catch (e) {
        return Icon(
          Icons.person,
          size: 50,
          color: Theme.of(context).colorScheme.primary,
        );
      }
    }
  }
}

