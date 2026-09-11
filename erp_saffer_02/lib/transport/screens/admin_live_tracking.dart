import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/bus_model.dart';
import '../models/bus_stop_model.dart';
import '../services/bus_service.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────
class AdminLiveTrackingScreen extends StatefulWidget {
  const AdminLiveTrackingScreen({Key? key}) : super(key: key);

  @override
  State<AdminLiveTrackingScreen> createState() =>
      _AdminLiveTrackingScreenState();
}

// ─── State ────────────────────────────────────────────────────────────────────
class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final BusService _busService = BusService();

  // Bus data
  List<BusModel> _buses = [];
  bool _loadingBuses = true;

  // Selected bus & stops
  BusModel? _selectedBus;
  List<BusStopModel> _stops = [];
  bool _loadingStops = false;

  // Telemetry
  double _speed = 40;
  double _heading = 90;

  // Broadcast state
  int? _activeIndex; // last stop that was broadcast
  String? _lastStatus;
  final Set<int> _sending = {}; // stops currently being POSTed

  // Pulse animation for the active stop node
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fetchBuses();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────
  Future<void> _fetchBuses() async {
    if (!mounted) return;
    setState(() => _loadingBuses = true);
    try {
      final all = await _busService.getBuses();
      if (!mounted) return;
      setState(() {
        _buses = all.where((b) => b.status.toUpperCase() == 'ACTIVE').toList();
        _loadingBuses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBuses = false);
      _snack('Failed to load buses: $e', Colors.redAccent);
    }
  }

  Future<void> _pickBus(BusModel bus) async {
    if (!mounted) return;
    setState(() {
      _selectedBus = bus;
      _stops = [];
      _loadingStops = true;
      _activeIndex = null;
      _lastStatus = null;
    });
    if (bus.route == null) {
      setState(() => _loadingStops = false);
      return;
    }
    try {
      final list = await _busService.getStops(bus.route!.id);
      if (!mounted) return;
      setState(() {
        _stops = list;
        _loadingStops = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStops = false);
      _snack('Failed to load stops: $e', Colors.redAccent);
    }
  }

  Future<void> _broadcast(
    int idx,
    double lat,
    double lng,
    String name,
    String status,
  ) async {
    if (_selectedBus == null || _sending.contains(idx)) return;
    setState(() => _sending.add(idx));
    try {
      await _busService.sendLocationUpdate(
        _selectedBus!.id,
        lat,
        lng,
        _speed,
        _heading,
        status,
      );
      if (!mounted) return;
      setState(() {
        _activeIndex = idx;
        _lastStatus = status;
        _sending.remove(idx);
      });
      _snack(
        '📡 ${_selectedBus!.busNumber} → $name · ${status == 'ARRIVED_AT_STOP' ? 'Arrived' : 'On Route'}',
        status == 'ARRIVED_AT_STOP' ? ErpColors.textPrimary : ErpColors.textPrimary,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending.remove(idx));
      _snack('Broadcast failed: $e', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      // ── App bar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        elevation: 0,
        leading: BackButton(color: ErpColors.textOnPrimary.withValues(alpha: 0.7)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_fixed, color: ErpColors.textOnPrimary, size: 19),
            SizedBox(width: 8),
            Text(
              'Live GPS Simulator',
              style: GoogleFonts.outfit(
                color: ErpColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: ErpColors.textOnPrimary.withValues(alpha: 0.7)),
            onPressed: _fetchBuses,
            tooltip: 'Refresh buses',
          ),
        ],
      ),

      // ── Body: single Column with Expanded ListView ───────────────────────
      body:
          _loadingBuses
              ? _loadingState('Loading active buses…')
              : Column(
                children: [
                  // Bus selector strip
                  _buildBusSelector(),

                  // Everything else scrolls together
                  Expanded(
                    child:
                        _selectedBus == null
                            ? _emptyPrompt()
                            : ListView(
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              children: [
                                // Bus info card
                                _buildBusHeader(),

                                // Info hint
                                _buildHint(
                                  'Tap "On Route" or "Arrived" on a stop to push a real-time GPS coordinate to the server.',
                                ),

                                // Telemetry sliders
                                _buildTelemetry(),

                                // Stops section
                                _buildStopsSection(),

                                // Quick presets
                                _buildQuickBroadcast(),

                                SizedBox(height: 40),
                              ],
                            ),
                  ),
                ],
              ),
    );
  }

  // ─── Bus selector row ───────────────────────────────────────────────────────
  Widget _buildBusSelector() {
    if (_buses.isEmpty) {
      return Container(
        color: ErpColors.bgWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          '---',
          style: GoogleFonts.outfit(color: ErpColors.textSecondary, fontSize: 12.5),
        ),
      );
    }
    return Container(
      color: ErpColors.bgWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Select Bus',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: ErpColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              itemCount: _buses.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final b = _buses[idx];
                final sel = _selectedBus?.id == b.id;
                return GestureDetector(
                  onTap: () => _pickBus(b),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? ErpColors.primary : ErpColors.bgWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? ErpColors.textOnPrimary : ErpColors.textPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: 16,
                          color: sel ? ErpColors.textOnPrimary : ErpColors.textMuted,
                        ),
                        SizedBox(width: 7),
                        Text(
                          b.busNumber,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: sel ? ErpColors.textOnPrimary : ErpColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // ─── Selected bus header ────────────────────────────────────────────────────
  Widget _buildBusHeader() {
    if (_selectedBus == null) return SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ErpColors.primary, ErpColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ErpColors.textOnPrimary,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ErpColors.textOnPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: ErpColors.textOnPrimary,
              size: 26,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedBus!.busNumber,
                  style: GoogleFonts.outfit(
                    color: ErpColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reg: ${_selectedBus!.registrationNumber}',
                  style: GoogleFonts.outfit(
                    color: ErpColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  'Driver: ${_selectedBus!.driver?.name ?? "Not assigned"}',
                  style: GoogleFonts.outfit(
                    color: ErpColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                if (_selectedBus!.route != null)
                  Text(
                    '📍 ${_selectedBus!.route!.routeName}',
                    style: GoogleFonts.outfit(
                      color: ErpColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (_activeIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ErpColors.textPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: ErpColors.textPrimary),
                  SizedBox(height: 3),
                  Text(
                    'LIVE',
                    style: GoogleFonts.outfit(
                      color: ErpColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Telemetry card (replaces raw sliders) ─────────────────────────────────
  Widget _buildTelemetry() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: ErpColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpColors.textPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1EFE9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.settings_input_antenna,
                  size: 15,
                  color: ErpColors.textPrimary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulation Parameters',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'These values are sent with every GPS broadcast and shown to students on their live tracking screen.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Speed ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: ErpColors.textPrimary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Bus Speed: ${_speed.toInt()} km/h',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  '---',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: ErpColors.textSecondary,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _speedChip(0, 'Stopped'),
                    _speedChip(20, '20 km/h'),
                    _speedChip(30, '30 km/h'),
                    _speedChip(40, '40 km/h'),
                    _speedChip(50, '50 km/h'),
                    _speedChip(60, '60 km/h'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Direction ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      size: 14,
                      color: ErpColors.textPrimary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Direction: ${_headingLabel(_heading)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  '---',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: ErpColors.textSecondary,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _compassChip('↑ North', 0),
                    _compassChip('↗ NE', 45),
                    _compassChip('→ East', 90),
                    _compassChip('↘ SE', 135),
                    _compassChip('↓ South', 180),
                    _compassChip('↙ SW', 225),
                    _compassChip('← West', 270),
                    _compassChip('↖ NW', 315),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedChip(int kmh, String label) {
    final bool sel = _speed.toInt() == kmh;
    return GestureDetector(
      onTap: () => setState(() => _speed = kmh.toDouble()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? ErpColors.textOnPrimary : ErpColors.textMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? ErpColors.textOnPrimary : ErpColors.textMuted,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: sel ? ErpColors.textOnPrimary : ErpColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _compassChip(String label, double deg) {
    final bool sel = (_heading - deg).abs() < 22;
    return GestureDetector(
      onTap: () => setState(() => _heading = deg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? ErpColors.textOnPrimary : ErpColors.textMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? ErpColors.textOnPrimary : ErpColors.textMuted,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: sel ? ErpColors.textOnPrimary : ErpColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _headingLabel(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'North';
    if (deg < 67.5) return 'North-East';
    if (deg < 112.5) return 'East';
    if (deg < 157.5) return 'South-East';
    if (deg < 202.5) return 'South';
    if (deg < 247.5) return 'South-West';
    if (deg < 292.5) return 'West';
    return 'North-West';
  }

  // ─── Stops section ──────────────────────────────────────────────────────────
  Widget _buildStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text(
                '---',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ErpColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              if (!_loadingStops && _stops.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ErpColors.textMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_stops.length} stops',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_loadingStops)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: const CircularProgressIndicator(color: ErpColors.primary),
            ),
          )
        else if (_selectedBus?.route == null)
          _warnBox(
            'This bus has no route assigned. Assign a route in Bus Management.',
            Colors.redAccent,
            Icons.route_rounded,
          )
        else if (_stops.isEmpty)
          _warnBox(
            'No stops found on this route. Add stops in Routes & Stops manager.',
            ErpColors.textPrimary,
            Icons.warning_amber_rounded,
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                _stops.length,
                (i) => _buildStopTile(_stops[i], i),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Single stop tile (no IntrinsicHeight, no Expanded in timeline) ─────────
  Widget _buildStopTile(BusStopModel stop, int index) {
    final isFirst = index == 0;
    final isLast = index == _stops.length - 1;
    final isActive = _activeIndex == index;
    final isPast = _activeIndex != null && index < _activeIndex!;
    final isBusy = _sending.contains(index);

    final Color nodeColor =
        isFirst
            ? ErpColors.textPrimary
            : isLast
            ? Colors.redAccent
            : ErpColors.textPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline column (fixed width, no Expanded) ──────────────────
        SizedBox(
          width: 32,
          child: Column(
            children: [
              // Top segment
              Container(
                width: 2,
                height: 14,
                color:
                    (!isFirst && isPast)
                        ? ErpColors.textMuted
                        : ErpColors.textPrimary,
              ),
              // Node dot
              AnimatedBuilder(
                animation: _pulse,
                builder:
                    (_, __) => Transform.scale(
                      scale: isActive ? (0.75 + 0.25 * _pulse.value) : 1.0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isActive
                                  ? nodeColor
                                  : isPast
                                  ? ErpColors.textMuted
                                  : ErpColors.textPrimary,
                          border: Border.all(
                            color:
                                isActive
                                    ? nodeColor
                                    : isPast
                                    ? ErpColors.textPrimary
                                    : nodeColor.withOpacity(0.45),
                            width: 2,
                          ),
                          boxShadow:
                              isActive
                                  ? [
                                    BoxShadow(
                                      color: nodeColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                  : null,
                        ),
                        child:
                            isPast && !isActive
                                ? Icon(
                                  Icons.check,
                                  size: 8,
                                  color: ErpColors.textPrimary,
                                )
                                : null,
                      ),
                    ),
              ),
              // Bottom segment (grows to match card height)
              if (!isLast)
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 50),
                    child: Container(
                      width: 2,
                      color:
                          isPast ? ErpColors.textMuted : ErpColors.textPrimary,
                    ),
                  ),
                )
              else
                SizedBox(height: 20),
            ],
          ),
        ),

        SizedBox(width: 10),

        // ── Stop card (takes remaining width) ───────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? nodeColor.withOpacity(0.04)
                      : ErpColors.bgWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? nodeColor.withOpacity(0.3) : ErpColors.textPrimary,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color: nodeColor.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          stop.stopName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isActive ? nodeColor : ErpColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isFirst) _badge('ORIGIN', ErpColors.textPrimary),
                      if (isLast && !isFirst)
                        _badge('TERMINAL', Colors.redAccent),
                    ],
                  ),
                  if (isActive) ...[
                    SizedBox(height: 4),
                    _badge(
                      _lastStatus == 'ARRIVED_AT_STOP'
                          ? '● ARRIVED'
                          : '● ON ROUTE',
                      _lastStatus == 'ARRIVED_AT_STOP'
                          ? ErpColors.textPrimary
                          : ErpColors.textPrimary,
                    ),
                  ],
                  SizedBox(height: 6),
                  // Meta row
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: ErpColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ETA: ${stop.estimatedArrivalTime}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: ErpColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${stop.latitude.toStringAsFixed(5)}, ${stop.longitude.toStringAsFixed(5)}',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  const Divider(height: 1),
                  SizedBox(height: 10),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: isBusy ? 'Sending…' : 'On Route',
                          icon: Icons.directions_rounded,
                          color: ErpColors.textPrimary,
                          busy: isBusy,
                          onTap:
                              () => _broadcast(
                                index,
                                stop.latitude,
                                stop.longitude,
                                stop.stopName,
                                'ON_ROUTE',
                              ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          label: isBusy ? 'Sending…' : 'Arrived',
                          icon: Icons.check_circle_rounded,
                          color: ErpColors.textPrimary,
                          busy: isBusy,
                          onTap:
                              () => _broadcast(
                                index,
                                stop.latitude,
                                stop.longitude,
                                stop.stopName,
                                'ARRIVED_AT_STOP',
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    margin: const EdgeInsets.only(left: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool busy,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: busy ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: busy ? color.withOpacity(0.05) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: busy ? color.withOpacity(0.4) : color,
            ),
          ),
        ],
      ),
    ),
  );

  // ─── Quick broadcast presets ────────────────────────────────────────────────
  Widget _buildQuickBroadcast() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ErpColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpColors.textPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 15, color: ErpColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Quick Broadcast Presets',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ErpColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _quickTile(
            label: 'Tambaram Junction',
            sublabel: 'Mark On Route',
            icon: Icons.train_rounded,
            color: ErpColors.textPrimary,
            lat: 12.8406,
            lng: 80.1534,
            status: 'ON_ROUTE',
          ),
          SizedBox(height: 10),
          _quickTile(
            label: 'College Main Gate',
            sublabel: 'Mark Arrived',
            icon: Icons.school_rounded,
            color: ErpColors.textPrimary,
            lat: 12.8794,
            lng: 80.0818,
            status: 'ARRIVED_AT_STOP',
          ),
        ],
      ),
    );
  }

  Widget _quickTile({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required double lat,
    required double lng,
    required String status,
  }) {
    final bool enabled = _selectedBus != null;
    return GestureDetector(
      onTap: enabled ? () => _broadcast(-1, lat, lng, label, status) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: color.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.send_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildHint(String msg) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: ErpColors.textMuted,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: ErpColors.textMuted),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: ErpColors.textPrimary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: GoogleFonts.outfit(fontSize: 11.5, color: ErpColors.textPrimary),
          ),
        ),
      ],
    ),
  );

  Widget _warnBox(String msg, Color color, IconData icon) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            msg,
            style: GoogleFonts.outfit(fontSize: 12.5, color: color),
          ),
        ),
      ],
    ),
  );

  Widget _loadingState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: ErpColors.primary),
        SizedBox(height: 16),
        Text(
          msg,
          style: GoogleFonts.outfit(color: ErpColors.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _emptyPrompt() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ErpColors.textMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gps_not_fixed,
              size: 48,
              color: ErpColors.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '---',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: ErpColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '---',
            style: GoogleFonts.outfit(fontSize: 13, color: ErpColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

