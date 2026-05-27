import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/api_error_message.dart';
import '../../../core/utils/api_media_url.dart';
import '../../../models/coach_profile.dart';
import '../../home/models/sports_club.dart';
import '../../home/providers/sports_clubs_provider.dart';
import '../providers/ai_matched_clubs_history_provider.dart';

final _publicSportsProvider =
    FutureProvider.autoDispose<List<({String code, String name})>>((ref) {
      return PlayGoApiClient().fetchSports();
    });

typedef _ChatLine = ({bool agent, String text});

enum _MatchScope { clubs, coaches, both }

/// Фазы диалога с «агентом» (вопросы по очереди).
enum _DialogPhase {
  pickScope,
  askCity,
  askSport,
  askAge,

  /// После выдачи результатов.
  finished,
}

/// Красная обводка как в shell; в светлой теме — белая заливка, в тёмной — без белой заливки.
ButtonStyle _aiAccentOutlinedButtonStyle(BuildContext context) {
  const c = Color(0xFFC62828);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fill = isDark ? Colors.transparent : Colors.white;
  return OutlinedButton.styleFrom(
    foregroundColor: c,
    backgroundColor: fill,
    side: const BorderSide(color: c, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    disabledForegroundColor: c.withValues(alpha: 0.45),
    disabledBackgroundColor: fill,
  );
}

class AiCoachMatchScreen extends ConsumerStatefulWidget {
  const AiCoachMatchScreen({super.key});

  @override
  ConsumerState<AiCoachMatchScreen> createState() => _AiCoachMatchScreenState();
}

class _AiCoachMatchScreenState extends ConsumerState<AiCoachMatchScreen> {
  final _scrollCtrl = ScrollController();
  final _cityCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  final List<_ChatLine> _lines = [];

  _DialogPhase _phase = _DialogPhase.pickScope;
  _MatchScope? _scope;

  /// `null` — любой вид спорта.
  String? _sportCodeFilter;

  /// Возраст для query к `/api/clubs`.
  int? _ageYears;

  List<SportsClub> _clubs = [];
  List<CoachProfile> _coaches = [];

  bool _loading = false;
  String? _inputError;
  String? _searchFatal;

  bool _scrollToEndQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final user = ref.read(authProvider).user;
      if (user != null && user.city.trim().isNotEmpty) {
        _cityCtrl.text = user.city.trim();
      }
      setState(() {
        _lines.add((agent: true, text: l10n.aiAgentWelcome));
      });
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _cityCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollToEndQueued) return;
    _scrollToEndQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEndQueued = false;
      if (!mounted || !_scrollCtrl.hasClients) return;
      final p = _scrollCtrl.position;
      final target = p.maxScrollExtent;
      if ((target - p.pixels).abs() > 0.5) {
        p.jumpTo(target);
      }
    });
  }

  bool get _clubsRelevant =>
      _scope == _MatchScope.clubs || _scope == _MatchScope.both;

  bool get _coachesRelevant =>
      _scope == _MatchScope.coaches || _scope == _MatchScope.both;

  void _onPickScope(_MatchScope s) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();
    final label = switch (s) {
      _MatchScope.clubs => l10n.aiAgentScopeClubs,
      _MatchScope.coaches => l10n.aiAgentScopeCoaches,
      _MatchScope.both => l10n.aiAgentScopeBoth,
    };
    setState(() {
      _lines.add((agent: false, text: label));
      _scope = s;
      _phase = _DialogPhase.askCity;
      _clubs = [];
      _coaches = [];
      _inputError = null;
      _searchFatal = null;
      _sportCodeFilter = null;
      _ageYears = null;
      _lines.add((agent: true, text: l10n.aiAgentAskCity));
    });
    _scrollToEnd();
  }

  void _submitCity() {
    final l10n = AppLocalizations.of(context)!;
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) {
      setState(() => _inputError = l10n.aiCoachCityHint);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _inputError = null;
      _lines.add((agent: false, text: city));
      _phase = _DialogPhase.askSport;
      _lines.add((agent: true, text: l10n.aiAgentAskSport));
    });
    _scrollToEnd();
  }

  String _sportUserLabel(
    AppLocalizations l10n,
    List<({String code, String name})> sports,
  ) {
    final code = _sportCodeFilter;
    if (code == null || code.isEmpty) return l10n.aiUserAnySport;
    for (final s in sports) {
      if (s.code == code) return s.name;
    }
    return code;
  }

  void _submitSport(
    AppLocalizations l10n,
    List<({String code, String name})> sports, {
    bool skipSport = false,
  }) {
    HapticFeedback.lightImpact();
    final userLine = _sportUserLabel(l10n, sports);
    if (_scope == _MatchScope.coaches) {
      setState(() {
        if (skipSport) {
          _sportCodeFilter = null;
        }
        _lines.add((agent: false, text: userLine));
        _lines.add((agent: true, text: l10n.aiAgentSearching));
      });
      _scrollToEnd();
      unawaited(_performSearch());
      return;
    }
    setState(() {
      if (skipSport) {
        _sportCodeFilter = null;
      }
      _lines.add((agent: false, text: userLine));
      _phase = _DialogPhase.askAge;
      _ageYears = null;
      _ageCtrl.clear();
      _inputError = null;
      _lines.add((agent: true, text: l10n.aiAgentAskAge));
    });
    _scrollToEnd();
  }

  Future<void> _performSearch() async {
    final city = _cityCtrl.text.trim();

    setState(() {
      _loading = true;
      _clubs = [];
      _coaches = [];
      _searchFatal = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final repo = ref.read(sportsClubsRepositoryProvider);

      final clubsFuture = _clubsRelevant
          ? repo.fetchClubsFiltered(
              city: city,
              sportCode: _sportCodeFilter,
              age: _ageYears,
            )
          : Future<List<SportsClub>>.value([]);

      final coachesFuture = _coachesRelevant
          ? PlayGoApiClient().searchCoachProfilesPublic(
              cityName: city,
              sportCode: _sportCodeFilter,
              limit: 48,
            )
          : Future<List<CoachProfile>>.value([]);

      final duo = await Future.wait([clubsFuture, coachesFuture]);
      final clubsFiltered = duo[0] as List<SportsClub>;
      final coachesFiltered = duo[1] as List<CoachProfile>;

      if (!mounted) return;

      setState(() {
        _lines.add((
          agent: true,
          text: l10n.aiAgentResultsSummary(
            clubsFiltered.length,
            coachesFiltered.length,
          ),
        ));
        _clubs = clubsFiltered;
        _coaches = coachesFiltered;
        _loading = false;
        _phase = _DialogPhase.finished;
      });
      if (_clubsRelevant && clubsFiltered.isNotEmpty) {
        unawaited(
          ref
              .read(aiMatchedClubsHistoryProvider.notifier)
              .prependFromSearch(clubsFiltered),
        );
      }
      _scrollToEnd();
    } on PlayGoApiException catch (e) {
      if (!mounted) return;
      final msg = friendlyApiError(e, AppLocalizations.of(context)!);
      setState(() {
        _loading = false;
        _searchFatal = msg;
        _phase = _DialogPhase.finished;
      });
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searchFatal = AppLocalizations.of(context)!.genericNetworkError;
        _phase = _DialogPhase.finished;
      });
      _scrollToEnd();
    }
  }

  void _restart() {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final user = ref.read(authProvider).user;
    setState(() {
      _lines.clear();
      _lines.add((agent: true, text: l10n.aiAgentWelcome));
      _phase = _DialogPhase.pickScope;
      _scope = null;
      _sportCodeFilter = null;
      _ageYears = null;
      _cityCtrl.clear();
      if (user != null && user.city.trim().isNotEmpty) {
        _cityCtrl.text = user.city.trim();
      }
      _ageCtrl.clear();
      _clubs = [];
      _coaches = [];
      _inputError = null;
      _searchFatal = null;
      _loading = false;
    });
    _scrollToEnd();
  }

  void _openMatchedClubsHistorySheet() {
    HapticFeedback.selectionClick();
    final rootContext = context;
    final l10n = AppLocalizations.of(rootContext)!;
    showModalBottomSheet<void>(
      context: rootContext,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final history = ref.watch(aiMatchedClubsHistoryProvider);
            final scheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12 + ShellLayout.navBarSpacerHeight(ctx),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.aiMatchedClubsHistoryTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.aiMatchedClubsHistoryHint,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(l10n.aiMatchedClubsHistoryEmpty),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: history.length,
                        separatorBuilder: (_, i) =>
                            Divider(height: 1, color: scheme.outlineVariant),
                        itemBuilder: (_, i) {
                          final e = history[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: scheme.surfaceContainerHighest,
                              backgroundImage:
                                  e.imageUrl != null && e.imageUrl!.isNotEmpty
                                  ? NetworkImage(e.imageUrl!)
                                  : null,
                              child:
                                  e.imageUrl != null && e.imageUrl!.isNotEmpty
                                  ? null
                                  : Icon(
                                      Icons.domain_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                            ),
                            title: Text(
                              e.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(e.city),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.outline,
                            ),
                            onTap: () {
                              Navigator.of(sheetCtx).pop();
                              if (mounted) {
                                rootContext.push('/club/${e.id}');
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitAge(AppLocalizations l10n, {bool skipped = false}) {
    HapticFeedback.lightImpact();
    if (skipped) {
      setState(() {
        _ageYears = null;
        _ageCtrl.clear();
        _inputError = null;
        _lines.add((agent: false, text: l10n.aiAgeSkipLabel));
        _lines.add((agent: true, text: l10n.aiAgentSearching));
      });
      _scrollToEnd();
      unawaited(_performSearch());
      return;
    }
    final parsed = int.tryParse(_ageCtrl.text.trim());
    if (parsed == null || parsed < 1 || parsed > 120) {
      setState(() => _inputError = l10n.errorValidation);
      return;
    }
    setState(() {
      _ageYears = parsed;
      _inputError = null;
      _lines.add((agent: false, text: '$parsed'));
      _lines.add((agent: true, text: l10n.aiAgentSearching));
    });
    _scrollToEnd();
    unawaited(_performSearch());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final sportsAsync = ref.watch(_publicSportsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.aiAgentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: l10n.aiMatchedClubsHistoryTooltip,
            onPressed: _openMatchedClubsHistorySheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          12 + ShellLayout.navBarSpacerHeight(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ..._lines.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChatBubble(agent: e.agent, text: e.text),
            ),
          ),
          if (_phase == _DialogPhase.pickScope && !_loading)
            _ScopeChips(onPick: _onPickScope),
          if (_phase == _DialogPhase.askCity && !_loading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.city,
                        hintText: l10n.aiCoachCityHintShort,
                        errorText: _inputError,
                      ),
                      onSubmitted: (_) => _submitCity(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: _aiAccentOutlinedButtonStyle(context),
                      onPressed: _loading ? null : _submitCity,
                      child: Text(l10n.next),
                    ),
                  ],
                ),
              ),
            ),
          if (_phase == _DialogPhase.askSport && !_loading)
            sportsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text(
                l10n.aiCoachSportsLoadFail,
                style: TextStyle(color: scheme.error),
              ),
              data: (sports) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String?>(
                          key: ValueKey<String?>(
                            _sportCodeFilter ?? 'sport_null',
                          ),
                          // ignore: deprecated_member_use
                          value:
                              _sportCodeFilter != null &&
                                  sports.any((s) => s.code == _sportCodeFilter)
                              ? _sportCodeFilter
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.aiCoachSportFilterLabel,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.aiCoachSportAll),
                            ),
                            ...sports.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.code,
                                child: Text(s.name),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _sportCodeFilter = v),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              OutlinedButton(
                                style: _aiAccentOutlinedButtonStyle(context),
                                onPressed: _loading
                                    ? null
                                    : () => _submitSport(
                                        l10n,
                                        sports,
                                        skipSport: true,
                                      ),
                                child: Text(l10n.aiCoachSportAll),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: _aiAccentOutlinedButtonStyle(context),
                                onPressed: _loading
                                    ? null
                                    : () => _submitSport(
                                        l10n,
                                        sports,
                                        skipSport: false,
                                      ),
                                child: Text(l10n.next),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_phase == _DialogPhase.askAge && !_loading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.aiAgentAgeFieldLabel,
                        helperText: l10n.aiAgentAgeFieldHelper,
                        helperMaxLines: 3,
                        errorText: _inputError,
                      ),
                      onSubmitted: (_) => _submitAge(l10n),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          OutlinedButton(
                            style: _aiAccentOutlinedButtonStyle(context),
                            onPressed: _loading
                                ? null
                                : () => _submitAge(l10n, skipped: true),
                            child: Text(l10n.aiAgeSkipLabel),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: _aiAccentOutlinedButtonStyle(context),
                            onPressed: _loading ? null : () => _submitAge(l10n),
                            child: Text(l10n.aiCoachSearchAction),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_searchFatal != null && !_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _searchFatal!,
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_clubs.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l10n.aiClubsHeading(_clubs.length),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ..._clubs.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ClubMatchCard(club: c),
              ),
            ),
          ],
          if (_clubsRelevant &&
              !_loading &&
              _phase == _DialogPhase.finished &&
              _clubs.isEmpty &&
              _searchFatal == null)
            Text(l10n.aiEmptyClubs, style: TextStyle(color: scheme.outline)),
          if (_coaches.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              l10n.aiCoachesHeading(_coaches.length),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ..._coaches.map(
              (coach) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CoachMatchCard(coach: coach),
              ),
            ),
          ],
          if (_coachesRelevant &&
              !_loading &&
              _phase == _DialogPhase.finished &&
              _coaches.isEmpty &&
              _searchFatal == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.aiEmptyCoaches,
                style: TextStyle(color: scheme.outline),
              ),
            ),
          if (_phase == _DialogPhase.finished && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  style: _aiAccentOutlinedButtonStyle(context),
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(l10n.aiRestart),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.agent, required this.text});

  final bool agent;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final bg = agent ? scheme.surfaceContainerHighest : scheme.primaryContainer;
    final fg = agent ? scheme.onSurface : scheme.onPrimaryContainer;
    final align = agent ? Alignment.centerLeft : Alignment.centerRight;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg.withValues(alpha: agent ? 0.92 : 0.94),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(agent ? 4 : 18),
              bottomRight: Radius.circular(agent ? 18 : 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: agent
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      agent ? '🤖' : '👤',
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (agent) ...[
                      const SizedBox(width: 10),
                      Text(
                        l10n.aiAgentName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopeChips extends StatelessWidget {
  const _ScopeChips({required this.onPick});

  final void Function(_MatchScope) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget btn(String label, _MatchScope s) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: OutlinedButton(
        style: _aiAccentOutlinedButtonStyle(context),
        onPressed: () => onPick(s),
        child: Text(label),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          btn(l10n.aiAgentScopeClubs, _MatchScope.clubs),
          btn(l10n.aiAgentScopeCoaches, _MatchScope.coaches),
          btn(l10n.aiAgentScopeBoth, _MatchScope.both),
        ],
      ),
    );
  }
}

class _ClubMatchCard extends StatelessWidget {
  const _ClubMatchCard({required this.club});

  final SportsClub club;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final img = club.imageUrls.isNotEmpty ? club.imageUrls.first : null;
    Widget leading;
    if (img != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          img,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder:
              // ignore: unused_element_parameter
              (context, error, stackTrace) =>
                  _ClubPlaceholder(size: 76, scheme: scheme),
        ),
      );
    } else {
      leading = _ClubPlaceholder(size: 76, scheme: scheme);
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/club/${club.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${club.city} · ${club.sport}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                    ),
                    if (club.minAge > 0 || club.maxAge < 99)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${club.minAge}–${club.maxAge}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.aiClubOpen,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubPlaceholder extends StatelessWidget {
  const _ClubPlaceholder({required this.size, required this.scheme});

  final double size;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.sports, color: scheme.primary, size: 32),
    );
  }
}

class _CoachMatchCard extends StatelessWidget {
  const _CoachMatchCard({required this.coach});

  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final uri = absoluteBackendMediaUrl(coach.photoUrl);
    final initials =
        '${coach.coachFirstName.isNotEmpty ? coach.coachFirstName[0] : ''}'
                '${coach.coachLastName.isNotEmpty ? coach.coachLastName[0] : ''}'
            .toUpperCase();

    final avatar = uri != null
        ? ClipOval(
            child: Image.network(
              uri,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder:
                  // ignore: unused_element_parameter
                  (context, error, stackTrace) =>
                      _CoachFallback(scheme: scheme, initials: initials),
            ),
          )
        : _CoachFallback(scheme: scheme, initials: initials);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: coach.clubId != null && coach.clubId!.isNotEmpty
            ? () {
                HapticFeedback.selectionClick();
                context.push('/club/${coach.clubId}');
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 54, height: 54, child: avatar),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.trainerDisplayName.isNotEmpty
                          ? coach.trainerDisplayName
                          : (coach.clubName ?? l10n.aiCoachUntitledCoach),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (coach.clubName != null &&
                        coach.clubName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l10n.aiCoachClubLine} '),
                            TextSpan(
                              text: coach.clubName!.trim(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (coach.clubCityDisplay.trim().isNotEmpty ||
                        coach.clubSportName.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          [
                            if (coach.clubCityDisplay.isNotEmpty)
                              coach.clubCityDisplay,
                            if (coach.clubSportName.isNotEmpty)
                              coach.clubSportName,
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.outline),
                        ),
                      ),
                    if ((coach.experienceYears ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${l10n.coachExperienceYearsLabel}: ${coach.experienceYears}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (coach.clubId != null && coach.clubId!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l10n.aiCoachOpenClub,
                          style: TextStyle(color: scheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachFallback extends StatelessWidget {
  const _CoachFallback({required this.scheme, required this.initials});

  final ColorScheme scheme;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 27,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
