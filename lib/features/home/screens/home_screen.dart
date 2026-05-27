import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/api_error_message.dart';
import '../../../core/widgets/shell_nav_bar_spacer.dart';
import '../models/sports_club.dart';
import '../providers/favorite_clubs_provider.dart';
import '../providers/sports_clubs_provider.dart';
import '../widgets/club_description_snippet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// `null` — шаг выбора вида спорта; иначе просмотр клубов только этой категории.
  String? _selectedSportCategory;

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(sportsClubsFeedProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _selectedSportCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'К категориям',
                onPressed: () {
                  setState(() => _selectedSportCategory = null);
                },
              )
            : null,
        title: Builder(
          builder: (context) {
            if (_selectedSportCategory != null) {
              return Text(_selectedSportCategory!);
            }
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.categoriesScreenTitle ?? 'Категории');
          },
        ),
      ),
      body: clubsAsync.when(
        data: (clubs) {
          if (_selectedSportCategory == null) {
            return _buildSportsCategoryStep(context, clubs);
          }
          final filtered = clubs
              .where((c) => c.sport == _selectedSportCategory)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: filtered.isEmpty
                    ? Column(
                        children: [
                          const Expanded(child: _EmptyState()),
                          const ShellNavBarSpacer(),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(sportsClubsFeedProvider);
                          await ref.read(sportsClubsFeedProvider.future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _ClubCard(club: filtered[index]);
                          },
                        ),
                      ),
              ),
              const ShellNavBarSpacer(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context) != null
                  ? friendlyApiError(error, AppLocalizations.of(context)!)
                  : error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSportsCategoryStep(BuildContext context, List<SportsClub> clubs) {
    if (clubs.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пока нет доступных клубов',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        ref.invalidate(sportsClubsFeedProvider);
                        await ref.read(sportsClubsFeedProvider.future);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const ShellNavBarSpacer(),
        ],
      );
    }

    final entries = _sportCategoryEntries(clubs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sportsClubsFeedProvider);
              await ref.read(sportsClubsFeedProvider.future);
            },
            child: LayoutBuilder(
              builder: (context, c) {
                const hPad = 16.0;
                const spacing = 12.0;
                final inner =
                    math.max(0.0, c.maxWidth - hPad * 2);
                final halfW = math.max(
                  0.0,
                  (inner - spacing) / 2,
                );
                final cellH =
                    halfW > 0 ? halfW / 2.4 : 56.0;
                final rowCount = (entries.length + 1) ~/ 2;

                Widget categoryTile(MapEntry<String, int> e) {
                  return SizedBox(
                    height: cellH,
                    width: double.infinity,
                    child: _SportCategoryTile(
                      sport: e.key,
                      onTap: () {
                        setState(() => _selectedSportCategory = e.key);
                      },
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: rowCount,
                  itemBuilder: (context, rowIdx) {
                    final i = rowIdx * 2;
                    final isLastRow = rowIdx == rowCount - 1;
                    final hasPairRight = i + 1 < entries.length;

                    final row = hasPairRight
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: categoryTile(entries[i]),
                              ),
                              const SizedBox(width: spacing),
                              Expanded(
                                child: categoryTile(entries[i + 1]),
                              ),
                            ],
                          )
                        : categoryTile(entries[i]);

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: isLastRow ? 0 : spacing),
                      child: row,
                    );
                  },
                );
              },
            ),
          ),
        ),
        const ShellNavBarSpacer(),
      ],
    );
  }

  /// Список пар (вид спорта, число клубов), по алфавиту по названию спорта.
  List<MapEntry<String, int>> _sportCategoryEntries(List<SportsClub> clubs) {
    final counts = <String, int>{};
    for (final c in clubs) {
      counts[c.sport] = (counts[c.sport] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return list;
  }
}

class _SportCategoryTile extends StatelessWidget {
  const _SportCategoryTile({
    required this.sport,
    required this.onTap,
  });

  final String sport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              sport,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClubCard extends ConsumerWidget {
  const _ClubCard({required this.club});

  final SportsClub club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(favoriteClubIdsProvider);
    final isFavorite = favorites.contains(club.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: InkWell(
                onTap: () => context.push('/club/${club.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                      const SizedBox(height: 8),
                      Text(
                        club.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: isFavorite
                  ? l10n.removeFromFavorites
                  : l10n.addToFavorites,
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => ref
                  .read(favoriteClubIdsProvider.notifier)
                  .toggle(club.id),
            ),
          ],
        ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 54,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 10),
            Text(
              'В этой категории пока нет клубов',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
