import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sports_club.dart';
import '../providers/sports_clubs_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCityArea = _allFilterValue;
  String _selectedSport = _allFilterValue;
  String _selectedAge = _allFilterValue;

  static const String _allFilterValue = 'all';
  static const List<String> _ageOptions = <String>[
    _allFilterValue,
    '6-9',
    '10-13',
    '14-17',
    '18+',
  ];

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(sportsClubsFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventum Clubs'),
        actions: [
          IconButton(
            tooltip: 'Фильтры',
            onPressed: () => _openFilters(context, clubsAsync.valueOrNull ?? const []),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: clubsAsync.when(
        data: (clubs) {
          final filtered = _applyFilters(clubs);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Доступные спортивные клубы',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _ActiveFiltersRow(
                cityArea: _selectedCityArea,
                sport: _selectedSport,
                age: _selectedAge,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(sportsClubsFeedProvider);
                          await ref.read(sportsClubsFeedProvider.future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _ClubCard(club: filtered[index]);
                          },
                        ),
                      ),
              ),
              if (clubs.isNotEmpty && filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    'Показано ${filtered.length} из ${clubs.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Не удалось загрузить ленту клубов.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _extractCityAreaOptions(List<SportsClub> clubs) {
    final values = clubs.map((c) => '${c.city} / ${c.district}').toSet().toList()
      ..sort();
    return <String>[_allFilterValue, ...values];
  }

  List<String> _extractSportOptions(List<SportsClub> clubs) {
    final values = clubs.map((c) => c.sport).toSet().toList()..sort();
    return <String>[_allFilterValue, ...values];
  }

  List<SportsClub> _applyFilters(List<SportsClub> clubs) {
    return clubs.where((club) {
      final cityAreaLabel = '${club.city} / ${club.district}';
      final cityMatches =
          _selectedCityArea == _allFilterValue || _selectedCityArea == cityAreaLabel;
      final sportMatches = _selectedSport == _allFilterValue || _selectedSport == club.sport;
      final ageMatches = _isAgeMatches(club, _selectedAge);
      return cityMatches && sportMatches && ageMatches;
    }).toList();
  }

  bool _isAgeMatches(SportsClub club, String selectedAge) {
    if (selectedAge == _allFilterValue) return true;
    final range = switch (selectedAge) {
      '6-9' => (6, 9),
      '10-13' => (10, 13),
      '14-17' => (14, 17),
      '18+' => (18, 100),
      _ => (0, 100),
    };
    final min = range.$1;
    final max = range.$2;
    return club.maxAge >= min && club.minAge <= max;
  }

  Future<void> _openFilters(BuildContext context, List<SportsClub> clubs) async {
    final cityAreaOptions = _extractCityAreaOptions(clubs);
    final sportOptions = _extractSportOptions(clubs);

    var draftCityArea = _selectedCityArea;
    var draftSport = _selectedSport;
    var draftAge = _selectedAge;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Фильтры клубов',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _FilterDropdown(
                      label: 'Город / район',
                      value: draftCityArea,
                      values: cityAreaOptions,
                      allLabel: 'Все',
                      onChanged: (value) => setLocalState(() => draftCityArea = value),
                    ),
                    const SizedBox(height: 12),
                    _FilterDropdown(
                      label: 'Вид спорта',
                      value: draftSport,
                      values: sportOptions,
                      allLabel: 'Все',
                      onChanged: (value) => setLocalState(() => draftSport = value),
                    ),
                    const SizedBox(height: 12),
                    _FilterDropdown(
                      label: 'Возраст пользователя',
                      value: draftAge,
                      values: _ageOptions,
                      allLabel: 'Все',
                      onChanged: (value) => setLocalState(() => draftAge = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setLocalState(() {
                                draftCityArea = _allFilterValue;
                                draftSport = _allFilterValue;
                                draftAge = _allFilterValue;
                              });
                            },
                            child: const Text('Сбросить'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _selectedCityArea = draftCityArea;
                                _selectedSport = draftSport;
                                _selectedAge = draftAge;
                              });
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Применить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final String allLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = values.contains(value) ? value : values.first;
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item == _HomeScreenState._allFilterValue ? allLabel : item),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});

  final SportsClub club;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              club.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(label: Text(club.sport)),
                Chip(label: Text('${club.city}, ${club.district}')),
                Chip(label: Text('${club.minAge}-${club.maxAge} лет')),
              ],
            ),
            const SizedBox(height: 8),
            Text(club.address, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              club.description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({
    required this.cityArea,
    required this.sport,
    required this.age,
  });

  final String cityArea;
  final String sport;
  final String age;

  @override
  Widget build(BuildContext context) {
    final filters = <String>[
      cityArea == _HomeScreenState._allFilterValue ? 'Город/район: все' : cityArea,
      sport == _HomeScreenState._allFilterValue ? 'Спорт: все' : sport,
      age == _HomeScreenState._allFilterValue ? 'Возраст: все' : age,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(label: Text(filter)),
              ),
            )
            .toList(),
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
              'Клубов по выбранным фильтрам не найдено',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
