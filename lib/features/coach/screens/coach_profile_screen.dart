import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/api_error_message.dart';
import '../../../core/utils/api_media_url.dart';
import '../../../core/widgets/shell_nav_bar_spacer.dart';
import '../../../models/coach_profile.dart';
import '../../home/models/sports_club.dart';
import '../../home/providers/sports_clubs_provider.dart';
import '../providers/coach_profile_provider.dart';

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myCoachProfileProvider);
    final clubsAsync = ref.watch(sportsClubsFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coachProfileTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is PlayGoApiException
                  ? friendlyApiError(e, l10n)
                  : l10n.genericNetworkError,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myCoachProfileProvider);
              await ref.read(myCoachProfileProvider.future);
            },
            child: clubsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    e is PlayGoApiException
                        ? friendlyApiError(e, l10n)
                        : l10n.genericNetworkError,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(sportsClubsFeedProvider),
                    child: Text(l10n.retry),
                  ),
                  const ShellNavBarSpacer(),
                ],
              ),
              data: (clubs) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    16 +
                        ShellLayout.floatingNavClearancePadding(
                            context),
                  ),
                  child: _CoachProfileForm(
                    key: ValueKey(profile?.id ?? 'new'),
                    initial: profile,
                    clubs: clubs,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CoachProfileForm extends ConsumerStatefulWidget {
  const _CoachProfileForm({
    super.key,
    required this.initial,
    required this.clubs,
  });

  final CoachProfile? initial;
  final List<SportsClub> clubs;

  @override
  ConsumerState<_CoachProfileForm> createState() =>
      _CoachProfileFormState();
}

class _CoachProfileFormState extends ConsumerState<_CoachProfileForm> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _expCtrl;
  String? _clubId;
  bool _submitting = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _specCtrl =
        TextEditingController(text: p?.specialization ?? '');
    _expCtrl = TextEditingController(
      text: p?.experienceYears?.toString() ?? '',
    );
    _clubId = p?.clubId;
  }

  @override
  void didUpdateWidget(covariant _CoachProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.clubs.map((c) => c.id).toSet();
    if (_clubId != null && !ids.contains(_clubId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _clubId = null);
      });
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _specCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final token = ref.read(authProvider).accessToken;
    if (token == null || token.isEmpty) return;

    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || x == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await x.readAsBytes();
      await PlayGoApiClient().uploadCoachProfilePhoto(
          token, bytes, x.name);
      if (!mounted) return;
      ref.invalidate(myCoachProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.coachPhotoUpdated),
          behavior: SnackBarBehavior.floating,
          margin: ShellLayout.snackBarMargin(context),
        ),
      );
    } on PlayGoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyApiError(e, l10n)),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            margin: ShellLayout.snackBarMargin(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final token = ref.read(authProvider).accessToken;
    if (token == null || token.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final draft = CoachProfile(
        id: widget.initial?.id ?? '',
        userId: widget.initial?.userId ?? '',
        bio: _bioCtrl.text.trim(),
        clubId: _clubId,
        specialization:
            _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
        experienceYears: _expCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_expCtrl.text.trim()),
      );
      await PlayGoApiClient().upsertMyCoachProfile(
        token,
        draft.toUpsertBody(),
      );
      ref.invalidate(myCoachProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.coachProfileSaved),
          behavior: SnackBarBehavior.floating,
          margin: ShellLayout.snackBarMargin(context),
        ),
      );
    } on PlayGoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyApiError(e, l10n)),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
          margin: ShellLayout.snackBarMargin(context),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final clubItems =
        widget.clubs.map((c) => MapEntry(c.id, c.name)).where(
              (e) => e.key.isNotEmpty && e.value.isNotEmpty,
            );

    String? effectiveClubId = _clubId;
    if (effectiveClubId != null &&
        !clubItems.any((e) => e.key == effectiveClubId)) {
      effectiveClubId = null;
    }

    final imgUrl = absoluteBackendMediaUrl(widget.initial?.photoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.coachProfileHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: scheme.surfaceContainerHighest,
                child: ClipOval(
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          width: 108,
                          height: 108,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.person, size: 48, color: scheme.primary),
                        )
                      : Icon(Icons.person, size: 48, color: scheme.primary),
                ),
              ),
              IconButton.filled(
                onPressed: _uploading ? null : _pickAndUploadPhoto,
                icon: _uploading
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.photo_camera_outlined, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _bioCtrl,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: l10n.coachBioLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.coachClubLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: effectiveClubId,
              isExpanded: true,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.coachClubNone),
                ),
                ...clubItems.map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _clubId = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _specCtrl,
          decoration: InputDecoration(
            labelText: l10n.coachSpecializationLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _expCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.coachExperienceYearsLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onInverseSurface,
                  ),
                )
              : Text(l10n.save),
        ),
        const ShellNavBarSpacer(),
      ],
    );
  }
}
