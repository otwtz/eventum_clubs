import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/play_go_api_client.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/api_error_message.dart';
import '../../../../core/l10n/language_button.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// URL документов (замените на реальные при публикации).
const _kLicenseUrl = 'https://example.com/terms';
const _kPrivacyUrl = 'https://example.com/privacy';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _photoPath;
  bool _agreeToLicense = false;
  bool _agreeToPrivacy = false;
  bool _confirmAdult = false;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && !(_formKey1.currentState?.validate() ?? false)) return;
    if (_currentStep == 1 && !(_formKey2.currentState?.validate() ?? false)) return;
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      setState(() => _photoPath = x.path);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            city: _cityController.text.trim(),
            photoPath: _photoPath,
          );
      if (!mounted) return;
      context.go('/home');
    } on PlayGoApiException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyApiError(e, l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyApiError(e, l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registration),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Form(
                    key: _formKey1,
                    child: _Step1(
                      l10n: l10n,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onNext: _nextStep,
                      onHasAccount: () => context.go('/login'),
                    ),
                  ),
                  Form(
                    key: _formKey2,
                    child: _Step2(
                      l10n: l10n,
                      usernameController: _usernameController,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      cityController: _cityController,
                      onNext: _nextStep,
                      onBack: _prevStep,
                      onHasAccount: () => context.go('/login'),
                    ),
                  ),
                  _Step3(
                    l10n: l10n,
                    photoPath: _photoPath,
                    agreeToLicense: _agreeToLicense,
                    agreeToPrivacy: _agreeToPrivacy,
                    confirmAdult: _confirmAdult,
                    onAgreeToLicense: (v) => setState(() => _agreeToLicense = v),
                    onAgreeToPrivacy: (v) => setState(() => _agreeToPrivacy = v),
                    onConfirmAdult: (v) => setState(() => _confirmAdult = v),
                    onPickPhoto: _pickPhoto,
                    onBack: _prevStep,
                    onSubmit: _submit,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.l10n,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onNext,
    required this.onHasAccount,
  });

  final AppLocalizations l10n;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onNext;
  final VoidCallback onHasAccount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: AppTheme.authInputDecoration(
                context,
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return l10n.email;
                if (!s.contains('@') || !s.contains('.')) return l10n.email;
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: AppTheme.authInputDecoration(
                context,
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.password;
                if (v.length < 6) return '6+';
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: Text(l10n.next),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onHasAccount,
              child: Text(l10n.hasAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2({
    required this.l10n,
    required this.usernameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.cityController,
    required this.onNext,
    required this.onBack,
    required this.onHasAccount,
  });

  final AppLocalizations l10n;
  final TextEditingController usernameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController cityController;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onHasAccount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: usernameController,
              decoration: AppTheme.authInputDecoration(
                context,
                labelText: l10n.nickname,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? l10n.nickname : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: AppTheme.authInputDecoration(
                context,
                labelText: l10n.firstName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? l10n.firstName : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: AppTheme.authInputDecoration(
                context,
                labelText: l10n.lastName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? l10n.lastName : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cityController,
              decoration: AppTheme.authInputDecoration(
                context,
                labelText: l10n.city,
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? l10n.city : null,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onBack,
                  child: Text(l10n.back),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14)),
                  child: Text(l10n.next),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onHasAccount,
              child: Text(l10n.hasAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  const _Step3({
    required this.l10n,
    required this.photoPath,
    required this.agreeToLicense,
    required this.agreeToPrivacy,
    required this.confirmAdult,
    required this.onAgreeToLicense,
    required this.onAgreeToPrivacy,
    required this.onConfirmAdult,
    required this.onPickPhoto,
    required this.onBack,
    required this.onSubmit,
    required this.isLoading,
  });

  final AppLocalizations l10n;
  final String? photoPath;
  final bool agreeToLicense;
  final bool agreeToPrivacy;
  final bool confirmAdult;
  final ValueChanged<bool> onAgreeToLicense;
  final ValueChanged<bool> onAgreeToPrivacy;
  final ValueChanged<bool> onConfirmAdult;
  final VoidCallback onPickPhoto;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isLoading;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = agreeToLicense && agreeToPrivacy && confirmAdult;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onPickPhoto,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                      child: photoPath != null
                          ? ClipOval(
                              child: kIsWeb
                                  ? Image.network(photoPath!, fit: BoxFit.cover)
                                  : Image.file(File(photoPath!), fit: BoxFit.cover),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.addPhoto,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _AgreementCheckbox(
              value: agreeToLicense,
              onChanged: onAgreeToLicense,
              prefix: l10n.agreeToLicense,
              linkText: l10n.licenseTermsLink,
              linkUrl: _kLicenseUrl,
              onOpenUrl: _openUrl,
            ),
            const SizedBox(height: 12),
            _AgreementCheckbox(
              value: agreeToPrivacy,
              onChanged: onAgreeToPrivacy,
              prefix: l10n.agreeToPrivacy,
              linkText: l10n.privacyPolicyLink,
              linkUrl: _kPrivacyUrl,
              onOpenUrl: _openUrl,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: confirmAdult,
                    onChanged: (v) => onConfirmAdult(v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.confirmAdult,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onBack,
                  child: Text(l10n.back),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: (isLoading || !canSubmit) ? null : onSubmit,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14)),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.register),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(l10n.hasAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({
    required this.value,
    required this.onChanged,
    required this.prefix,
    required this.linkText,
    required this.linkUrl,
    required this.onOpenUrl,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String prefix;
  final String linkText;
  final String linkUrl;
  final Future<void> Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(text: prefix),
                  TextSpan(
                    text: linkText,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => onOpenUrl(linkUrl),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
