import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/api_error_message.dart';
import '../../../core/widgets/shell_nav_bar_spacer.dart';
import '../../home/models/sports_club.dart';
import '../../home/providers/favorite_clubs_provider.dart';
import '../../home/providers/sports_clubs_provider.dart';
import '../../home/widgets/club_description_snippet.dart';

class MyClubsScreen extends ConsumerWidget {
  const MyClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(favoriteClubIdsProvider);
    final clubsAsync = ref.watch(sportsClubsFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myClubsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: clubsAsync.when(
        data: (clubs) {
          Future<void> reload() async {
            ref.invalidate(sportsClubsFeedProvider);
            await ref.read(sportsClubsFeedProvider.future);
          }

          final list = clubs
              .where((c) => favorites.contains(c.id))
              .toList();

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  Icon(
                    Icons.star_border_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.myClubsEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.myClubsEmptyHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const ShellNavBarSpacer(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == list.length) {
                  return const ShellNavBarSpacer();
                }
                return _FavoriteClubTile(club: list[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyApiError(e, l10n),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(sportsClubsFeedProvider),
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

class _FavoriteClubTile extends ConsumerWidget {
  const _FavoriteClubTile({required this.club});

  final SportsClub club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/club/${club.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ClubDescriptionSnippet(
                      description: club.description,
                      showFullLabel: l10n.clubDescriptionShowFull,
                      showLessLabel: l10n.clubDescriptionShowLess,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.removeFromFavorites,
                icon: Icon(
                  Icons.star_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () =>
                    ref.read(favoriteClubIdsProvider.notifier).toggle(club.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
