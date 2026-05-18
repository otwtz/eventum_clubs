import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/api_error_message.dart';
import '../../../core/utils/format_rub.dart';
import '../../../core/widgets/shell_nav_bar_spacer.dart';
import '../../../models/user_subscription.dart';
import '../providers/user_subscriptions_provider.dart';

class MySubscriptionsScreen extends ConsumerWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(mySubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySubscriptionsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        data: (items) {
          Future<void> reload() async {
            ref.invalidate(mySubscriptionsProvider);
            await ref.read(mySubscriptionsProvider.future);
          }

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.25,
                  ),
                  Text(
                    l10n.subscriptionsEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const ShellNavBarSpacer(),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const ShellNavBarSpacer();
                }
                return _SubscriptionCard(
                  subscription: items[index],
                  l10n: l10n,
                );
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
                  e is PlayGoApiException
                      ? friendlyApiError(e, l10n)
                      : l10n.genericNetworkError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(mySubscriptionsProvider),
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

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.l10n,
  });

  final UserSubscription subscription;
  final AppLocalizations l10n;

  String _title() {
    if (subscription.title.isNotEmpty) return subscription.title;
    if (subscription.clubName.isNotEmpty) return subscription.clubName;
    if (subscription.sportName.isNotEmpty) return subscription.sportName;
    return l10n.subscriptionUntitled;
  }

  String _statusLabel() {
    return switch (subscription.status) {
      UserSubscriptionStatus.active => l10n.subscriptionStatusActive,
      UserSubscriptionStatus.expired => l10n.subscriptionStatusExpired,
      UserSubscriptionStatus.cancelled => l10n.subscriptionStatusCancelled,
    };
  }

  Color _statusColor(ColorScheme scheme) {
    return switch (subscription.status) {
      UserSubscriptionStatus.active => scheme.primary,
      UserSubscriptionStatus.expired => scheme.onSurfaceVariant,
      UserSubscriptionStatus.cancelled => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[];
    if (subscription.priceCents > 0) {
      meta.add(formatRubFromKopecks(context, subscription.priceCents));
    }
    if (subscription.durationDays > 0) {
      meta.add(l10n.subscriptionDurationDays(subscription.durationDays));
    }

    final scopeLines = <String>[];
    if (subscription.isClubScoped) {
      final name = subscription.clubName.trim();
      if (name.isNotEmpty) {
        scopeLines.add(l10n.subscriptionClubNamed(name));
      } else {
        scopeLines.add(l10n.clubPassScopeClub);
      }
    }
    if (subscription.sportId != null &&
        subscription.sportId!.trim().isNotEmpty) {
      final name = subscription.sportName.trim();
      if (name.isNotEmpty) {
        scopeLines.add(l10n.subscriptionSportNamed(name));
      } else {
        scopeLines.add(l10n.clubPassScopeSport);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _title(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(scheme).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(scheme),
                    ),
                  ),
                ),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meta.join(' · '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (scopeLines.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...scopeLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
