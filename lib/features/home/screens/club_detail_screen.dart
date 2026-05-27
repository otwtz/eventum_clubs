import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/play_go_api_client.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/api_error_message.dart';
import '../../../../core/utils/api_media_url.dart';
import '../../../../core/constants/shell_layout.dart';
import '../../../../core/widgets/shell_nav_bar_spacer.dart';
import '../models/club_details.dart';
import '../providers/sports_clubs_provider.dart';
import '../widgets/club_enroll_sheet.dart';
import '../providers/favorite_clubs_provider.dart';

class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final String clubId;

  static String _weekdayShort(AppLocalizations l10n, int? day) {
    return switch (day) {
      1 => l10n.clubDayMon,
      2 => l10n.clubDayTue,
      3 => l10n.clubDayWed,
      4 => l10n.clubDayThu,
      5 => l10n.clubDayFri,
      6 => l10n.clubDaySat,
      7 => l10n.clubDaySun,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(clubDetailProvider(clubId));

    return async.when(
      data: (club) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final fav = ref.watch(favoriteClubIdsProvider);
                final isFav = fav.contains(clubId);
                return IconButton(
                  tooltip: isFav
                      ? l10n.removeFromFavorites
                      : l10n.addToFavorites,
                  icon: Icon(
                    isFav
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                  onPressed: () => ref
                      .read(favoriteClubIdsProvider.notifier)
                      .toggle(clubId),
                );
              },
            ),
          ],
        ),
        body: _ClubDetailBody(
          club: club,
          l10n: l10n,
          onEnroll: () {
            showClubEnrollOptionsSheet(
              context: context,
              club: club,
              onConfirmed: (choice) {
                final text = choice.when(
                  freeTrial: () => l10n.clubEnrollAckFree,
                  pass: (p) => l10n.clubEnrollAckPass(p.title),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(text),
                    behavior: SnackBarBehavior.floating,
                    margin: ShellLayout.snackBarMargin(context),
                  ),
                );
              },
            );
          },
          onOpenMaps: (url) async {
            final uri = Uri.tryParse(url);
            if (uri == null) return;
            if (!await canLaunchUrl(uri)) return;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e is PlayGoApiException
                      ? friendlyApiError(e, l10n)
                      : l10n.genericNetworkError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(clubDetailProvider(clubId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClubDetailBody extends StatelessWidget {
  const _ClubDetailBody({
    required this.club,
    required this.l10n,
    required this.onEnroll,
    required this.onOpenMaps,
  });

  final ClubDetails club;
  final AppLocalizations l10n;
  final VoidCallback onEnroll;
  final Future<void> Function(String url) onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = absoluteBackendMediaUrl(club.imageUrl);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.sports, size: 48, color: scheme.primary),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              club.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(club.sport)),
                if (club.city.isNotEmpty) Chip(label: Text(club.city)),
                Chip(label: Text('${club.minAge}–${club.maxAge}')),
                if (club.kind != null && club.kind!.isNotEmpty)
                  Chip(label: Text(club.kind!)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, color: scheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    club.address,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          if (club.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                l10n.clubAbout,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                club.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l10n.clubCoaches,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (club.coaches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.clubNoCoaches,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...club.coaches.map(
              (c) => ListTile(
                leading: Icon(Icons.person_outline, color: scheme.primary),
                title: Text(c),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.clubSchedule,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (club.schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.clubNoSchedule,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...club.schedules.map((s) {
              final day = ClubDetailScreen._weekdayShort(l10n, s.dayOfWeek);
              final time =
                  '${s.startTime}${s.endTime.isNotEmpty ? ' – ${s.endTime}' : ''}';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title.isEmpty ? l10n.clubSchedule : s.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (day.isNotEmpty || time.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [day, time].where((e) => e.isNotEmpty).join(' · '),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (s.ageGroup.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(s.ageGroup),
                      ],
                      if (s.coachName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(s.coachName),
                      ],
                      if (s.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          s.note,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          if (club.yandexMapsUrl != null &&
              club.yandexMapsUrl!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => onOpenMaps(club.yandexMapsUrl!.trim()),
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.clubOpenInMaps),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton(
              onPressed: onEnroll,
              child: Text(l10n.clubEnrollTraining),
            ),
          ),
          const ShellNavBarSpacer(),
        ],
      ),
    );
  }
}
