import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/constants/shell_layout.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/map_preferences_provider.dart';
import '../../../../core/utils/city_coordinates.dart';
import '../../home/models/sports_club.dart';
import '../../home/providers/sports_clubs_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      cancelPreviousAnimations: true,
    );
  }

  @override
  void dispose() {
    try {
      final camera = _animatedMapController.mapController.camera;
      ref.read(mapPreferencesProvider.notifier).savePosition(
            camera.center.latitude,
            camera.center.longitude,
            camera.zoom,
          );
    } catch (_) {}
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(sportsClubsFeedProvider);
    final savedPosition = ref.watch(mapPreferencesProvider);
    final userCity = ref.watch(userResidenceCityProvider);

    // Приоритет: город из регистрации → сохранённая позиция → центр по умолчанию
    LatLng initialCenter = _defaultCenter;
    double initialZoom = 10.0;
    if (userCity != null && userCity.trim().isNotEmpty) {
      initialCenter = CityCoordinates.get(userCity);
      initialZoom = 11.0;
    } else if (savedPosition != null) {
      initialCenter = LatLng(savedPosition.lat, savedPosition.lon);
      initialZoom = savedPosition.zoom;
    }

    return Scaffold(
      body: clubsAsync.when(
        data: (clubs) => _MapContent(
          animatedMapController: _animatedMapController,
          clubs: clubs,
          initialCenter: initialCenter,
          initialZoom: initialZoom,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _MapContent(
          animatedMapController: _animatedMapController,
          clubs: const [],
          errorMessage: err.toString(),
          initialCenter: initialCenter,
          initialZoom: initialZoom,
        ),
      ),
    );
  }
}

class _MapContent extends StatefulWidget {
  const _MapContent({
    required this.animatedMapController,
    required this.clubs,
    this.errorMessage,
    required this.initialCenter,
    required this.initialZoom,
  });

  final AnimatedMapController animatedMapController;
  final List<SportsClub> clubs;
  final String? errorMessage;
  final LatLng initialCenter;
  final double initialZoom;

  @override
  State<_MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<_MapContent> {
  LatLng? _userLocation;
  LatLng? _lastKnownForSort;
  bool _locationLoading = false;
  String? _locationError;

  /// Не более 10 ближайших к якорной точке клубов на полосе над навигацией.
  static const int _maxNearbyChips = 10;
  static const double _nearbyBarHeight = 60;

  @override
  void initState() {
    super.initState();
    _loadLastKnownForNearby();
  }

  Future<void> _loadLastKnownForNearby() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (!mounted || p == null) return;
      setState(() {
        _lastKnownForSort = LatLng(p.latitude, p.longitude);
      });
    } catch (_) {}
  }

  LatLng _anchorForNearbySort() {
    return _userLocation ?? _lastKnownForSort ?? widget.initialCenter;
  }

  List<SportsClub> _nearestClubsWithCoords(List<SportsClub> clubs) {
    final withCoords = clubs
        .where((c) => c.latitude != 0 || c.longitude != 0)
        .toList();
    if (withCoords.isEmpty) return const [];
    final anchor = _anchorForNearbySort();
    withCoords.sort((a, b) {
      final da = Geolocator.distanceBetween(
        anchor.latitude,
        anchor.longitude,
        a.latitude,
        a.longitude,
      );
      final db = Geolocator.distanceBetween(
        anchor.latitude,
        anchor.longitude,
        b.latitude,
        b.longitude,
      );
      return da.compareTo(db);
    });
    if (withCoords.length <= _maxNearbyChips) return withCoords;
    return withCoords.sublist(0, _maxNearbyChips);
  }

  Future<void> _centerOnUser() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = l10n.locationDisabled;
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = l10n.locationDeniedForever;
          _locationLoading = false;
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = l10n.locationDenied;
          _locationLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = latLng;
        _locationLoading = false;
        _locationError = null;
      });

      widget.animatedMapController.centerOnPoint(latLng, zoom: 14);
    } catch (e) {
      setState(() {
        _locationError = l10n.locationError;
        _locationLoading = false;
      });
    }
  }

  void _zoomIn() {
    widget.animatedMapController.animatedZoomIn();
  }

  void _zoomOut() {
    widget.animatedMapController.animatedZoomOut();
  }

  void _showMapClubPreview(BuildContext context, SportsClub club) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              16 + ShellLayout.floatingNavClearancePadding(sheetContext),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.apartment_rounded, color: scheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        club.name,
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(club.sport),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(club.cityAreaLabel),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${club.minAge}–${club.maxAge}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        club.address,
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (club.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    club.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.mapClubBriefHint,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (context.mounted) {
                      context.push('/club/${club.id}');
                    }
                  },
                  child: Text(l10n.mapGoToSchedule),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Тёмная тема: нативно тёмные тайлы Carto. Не использовать
  /// [darkModeTilesContainerBuilder] — он инвертирует цвета и портит уже тёмные тайлы.
  Widget _buildTileLayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileProvider = NetworkTileProvider(silenceExceptions: true);
    if (isDark) {
      return TileLayer(
        urlTemplate:
            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c', 'd'],
        fallbackUrl:
            'https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.eventum.play_go',
        tileProvider: tileProvider,
      );
    }
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      fallbackUrl:
          'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.eventum.play_go',
      tileProvider: tileProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navPad = ShellLayout.navBarSpacerHeight(context);

    final withCoords = widget.clubs
        .where((club) => club.latitude != 0 || club.longitude != 0)
        .toList();

    final nearestRow = _nearestClubsWithCoords(widget.clubs);
    final nearbyBarLift =
        nearestRow.isEmpty ? 0.0 : _nearbyBarHeight;

    final markers = <Marker>[
      ...withCoords.map(
        (club) => Marker(
          point: LatLng(club.latitude, club.longitude),
          width: _ClubMarker.markerWidth,
          height: _ClubMarker.markerHeight,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showMapClubPreview(context, club),
            child: const _ClubMarker(),
          ),
        ),
      ),
      if (_userLocation != null)
        Marker(
          point: _userLocation!,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: const _UserLocationMarker(),
        ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return Stack(
      children: [
        Positioned.fill(
          child: _MapGridBackground(color: bgColor),
        ),
        FlutterMap(
          mapController: widget.animatedMapController.mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            backgroundColor: Colors.transparent,
          ),
          children: [
            _buildTileLayer(context),
            MarkerLayer(markers: markers),
          ],
        ),
        if (widget.errorMessage != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Не удалось загрузить клубы: ${widget.errorMessage}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 12,
          bottom: navPad + 12 + nearbyBarLift,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.my_location,
                  onPressed: _locationLoading ? null : _centerOnUser,
                  child: _locationLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (_locationError != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: navPad + nearbyBarLift + 8,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _locationError = null),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (nearestRow.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: navPad,
            height: _nearbyBarHeight,
            child: _NearbyClubsStrip(
              clubs: nearestRow,
              onSelect: (club) {
                widget.animatedMapController.centerOnPoint(
                  LatLng(club.latitude, club.longitude),
                  zoom: 15,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NearbyClubsStrip extends StatelessWidget {
  const _NearbyClubsStrip({
    required this.clubs,
    required this.onSelect,
  });

  final List<SportsClub> clubs;
  final ValueChanged<SportsClub> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: clubs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final club = clubs[index];
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 168),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(club),
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.22),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    club.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    this.child,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child ??
              Icon(
                icon,
                color: onPressed != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withValues(alpha: 0.2),
        border: Border.all(color: Colors.blue, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 32),
      ),
    );
  }
}

class _ClubMarker extends StatelessWidget {
  const _ClubMarker();

  static IconData get _clubGlyph => Icons.apartment_rounded;

  static const double _iconMin = 8;
  static const double _iconMax = 24;

  /// Совпадает с [Marker.width] / [SizedBox] — запас под круг при max иконке.
  static const double markerWidth = 44;

  /// Совпадает с [Marker.height]: max диаметр + наконечник + небольшой запас.
  static const double markerHeight = 52;

  static double _zoomT(double zoom) {
    const minZ = 3.0;
    const maxZ = 18.0;
    return ((zoom - minZ) / (maxZ - minZ)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _zoomT(MapCamera.of(context).zoom);
    final iconSize = _iconMin + t * (_iconMax - _iconMin);

    final diameter = 14.0 + t * 20.0;
    final borderW = 1.0 + t * 0.5;
    final tipW = 8.0 + t * 8.0;
    final tipH = 4.0 + t * 4.0;
    final blur = 2.0 + t * 3.0;
    final offY = 1.0 + t;

    return SizedBox(
      width: markerWidth,
      height: markerHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.01),
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.primary,
                  width: borderW,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: blur,
                    offset: Offset(0, offY),
                  ),
                ],
              ),
              child: Icon(
                _clubGlyph,
                size: iconSize,
                color: scheme.primary,
              ),
            ),
            CustomPaint(
              size: Size(tipW, tipH),
              painter: _MapPinTipPainter(color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Нижняя «игла» пина карты.
class _MapPinTipPainter extends CustomPainter {
  _MapPinTipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}

const _defaultCenter = LatLng(55.7558, 37.6173);

/// Тонкая сетка серого цвета для фона карты; цвет фона адаптируется под тему.
class _MapGridBackground extends StatelessWidget {
  const _MapGridBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: CustomPaint(
        painter: _GridPainter(
          lineColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.lineColor});

  final Color lineColor;
  static const double step = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..strokeWidth = 1;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
