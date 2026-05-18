import 'package:flutter/material.dart';

import '../../../core/constants/shell_layout.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/format_rub.dart';
import '../models/club_details.dart';

/// Bottom sheet: бесплатная первая тренировка или абонемент клуба.
Future<void> showClubEnrollOptionsSheet({
  required BuildContext context,
  required ClubDetails club,
  required void Function(ClubEnrollChoice choice) onConfirmed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _ClubEnrollSheetBody(
        club: club,
        l10n: AppLocalizations.of(sheetContext)!,
        onConfirmed: (choice) {
          Navigator.of(sheetContext).pop();
          onConfirmed(choice);
        },
      );
    },
  );
}

sealed class ClubEnrollChoice {
  const ClubEnrollChoice();

  T when<T>({
    required T Function() freeTrial,
    required T Function(ClubPassOption pass) pass,
  }) {
    return switch (this) {
      ClubEnrollFreeTrial() => freeTrial(),
      ClubEnrollPassOption(:final option) => pass(option),
    };
  }
}

class ClubEnrollFreeTrial extends ClubEnrollChoice {
  const ClubEnrollFreeTrial();
}

class ClubEnrollPassOption extends ClubEnrollChoice {
  const ClubEnrollPassOption(this.option);
  final ClubPassOption option;
}

class _ClubEnrollSheetBody extends StatefulWidget {
  const _ClubEnrollSheetBody({
    required this.club,
    required this.l10n,
    required this.onConfirmed,
  });

  final ClubDetails club;
  final AppLocalizations l10n;
  final void Function(ClubEnrollChoice choice) onConfirmed;

  @override
  State<_ClubEnrollSheetBody> createState() => _ClubEnrollSheetBodyState();
}

class _ClubEnrollSheetBodyState extends State<_ClubEnrollSheetBody> {
  static const Object _freeKey = Object();

  late Object _selectedKey;

  @override
  void initState() {
    super.initState();
    _selectedKey = _freeKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final scheme = Theme.of(context).colorScheme;
    final passes = widget.club.passes;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + ShellLayout.floatingNavClearancePadding(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.clubEnrollSheetTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.club.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioGroup<Object>(
                    groupValue: _selectedKey,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedKey = v);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RadioListTile<Object>(
                          value: _freeKey,
                          title: Text(l10n.clubEnrollFreeFirst),
                          subtitle: Text(l10n.clubEnrollFreeFirstSubtitle),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (passes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              l10n.clubEnrollNoPassesHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.clubEnrollPassSection,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ...passes.map(
                            (p) => RadioListTile<Object>(
                              value: p.id,
                              title: Text(p.title),
                              subtitle: _passSubtitle(context, p, l10n),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final choice = _choiceFromKey(_selectedKey, passes);
                      widget.onConfirmed(choice);
                    },
                    child: Text(l10n.clubEnrollContinue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ClubEnrollChoice _choiceFromKey(Object key, List<ClubPassOption> passes) {
    if (identical(key, _freeKey)) return const ClubEnrollFreeTrial();
    for (final p in passes) {
      if (p.id == key) return ClubEnrollPassOption(p);
    }
    return const ClubEnrollFreeTrial();
  }
}

Widget? _passSubtitle(
  BuildContext context,
  ClubPassOption p,
  AppLocalizations l10n,
) {
  final parts = <String>[];
  if (p.priceCents > 0) {
    parts.add(formatRubFromKopecks(context, p.priceCents));
  }
  if (p.durationDays > 0) {
    parts.add(l10n.subscriptionDurationDays(p.durationDays));
  }
  final hasClub = p.clubId != null && p.clubId!.trim().isNotEmpty;
  final hasSport = p.sportId != null && p.sportId!.trim().isNotEmpty;
  if (hasClub) {
    parts.add(l10n.clubPassScopeClub);
  } else if (hasSport) {
    parts.add(l10n.clubPassScopeSport);
  }
  if (parts.isEmpty) return null;
  return Text(parts.join(' · '));
}
