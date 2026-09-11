import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/route_model.dart';
import '../models/bus_stop_model.dart';
import '../services/bus_service.dart';
import 'route_map_detail.dart';

class AdminManageRoutesScreen extends StatefulWidget {
  const AdminManageRoutesScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageRoutesScreen> createState() =>
      _AdminManageRoutesScreenState();
}

class _AdminManageRoutesScreenState extends State<AdminManageRoutesScreen> {
  final BusService _busService = BusService();
  List<RouteModel> _routes = [];
  // Map from routeId → list of stops (null = still loading)
  final Map<int, List<BusStopModel>?> _routeStops = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  // ── Data Loaders ──────────────────────────────────────────────────────────

  Future<void> _loadRoutes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _busService.getRoutes();
      if (!mounted) return;
      setState(() {
        _routes = list;
        _isLoading = false;
        // Mark every route as "pending" stop load
        for (final r in list) {
          _routeStops[r.id] = null;
        }
      });
      // Kick off stop loading in parallel
      for (final r in list) {
        _loadStops(r.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadStops(int routeId) async {
    try {
      final stops = await _busService.getStops(routeId);
      if (!mounted) return;
      setState(() => _routeStops[routeId] = stops);
    } catch (e) {
      if (!mounted) return;
      // Mark as empty list so UI shows "no stops" rather than spinner
      setState(() => _routeStops[routeId] = []);
      debugPrint('Error loading stops for route $routeId: $e');
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showRouteDialog({RouteModel? route}) {
    final nameController = TextEditingController(text: route?.routeName ?? '');
    final descController = TextEditingController(
      text: route?.description ?? '',
    );
    String status = route?.status ?? 'ACTIVE';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlg) => AlertDialog(
                  backgroundColor: ErpColors.bgWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ErpColors.textMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          route == null ? Icons.add_road : Icons.edit_road,
                          color: ErpColors.textPrimary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        route == null ? 'Add New Route' : 'Edit Route',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ErpTextField(
                            controller: nameController,
                            label: 'Route Name *',
                            hint: 'e.g. Tambaram → College',
                            prefixIcon: Icons.route,
                          ),
                          SizedBox(height: 14),
                          ErpTextField(
                            controller: descController,
                            maxLines: 2,
                            label: 'Description',
                            hint: 'Short description of the route',
                            prefixIcon: Icons.notes,
                          ),
                          SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.toggle_on_outlined),
                            ),
                            dropdownColor: ErpColors.bgWhite,
                            items: [
                              DropdownMenuItem(
                                value: 'ACTIVE',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'INACTIVE',
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlg(() => status = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(color: ErpColors.textMuted),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save_outlined, size: 16),
                      label: Text('Save Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ErpColors.primary,
                        foregroundColor: ErpColors.textPrimary,
                        minimumSize: const Size(120, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final routeName = nameController.text.trim();
                        if (routeName.isEmpty) {
                          _showSnackBar(
                            'Route name is required.',
                            isError: true,
                          );
                          return;
                        }
                        final target = RouteModel(
                          id: route?.id ?? 0,
                          routeName: routeName,
                          description: descController.text.trim(),
                          status: status,
                        );
                        Navigator.pop(ctx);
                        try {
                          if (route == null) {
                            await _busService.createRoute(target);
                          } else {
                            await _busService.updateRoute(route.id, target);
                          }
                          _showSnackBar('Route saved successfully!');
                          _loadRoutes();
                        } catch (e) {
                          _showSnackBar('Failed: $e', isError: true);
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  void _showStopDialog(int routeId, {BusStopModel? stop}) {
    final nameCtrl = TextEditingController(text: stop?.stopName ?? '');
    final latCtrl = TextEditingController(
      text: stop != null ? stop.latitude.toString() : '',
    );
    final lngCtrl = TextEditingController(
      text: stop != null ? stop.longitude.toString() : '',
    );
    // Auto-suggest next order number
    final currentStops = _routeStops[routeId] ?? [];
    final nextOrder =
        stop?.stopOrder ??
        (currentStops.isEmpty
            ? 1
            : (currentStops
                    .map((s) => s.stopOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1));
    final orderCtrl = TextEditingController(text: nextOrder.toString());
    final etaCtrl = TextEditingController(
      text: stop?.estimatedArrivalTime ?? '08:00 AM',
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ErpColors.textMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stop == null
                        ? Icons.add_location_alt_outlined
                        : Icons.edit_location_alt_outlined,
                    color: ErpColors.textPrimary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  stop == null ? 'Add Stop' : 'Edit Stop',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: ErpColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErpTextField(
                      controller: nameCtrl,
                      label: 'Stop Name *',
                      hint: 'e.g. Tambaram Bus Stand',
                      prefixIcon: Icons.place_outlined,
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ErpTextField(
                            controller: latCtrl,
                            label: 'Latitude *',
                            hint: '12.9229',
                            prefixIcon: Icons.gps_fixed,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ErpTextField(
                            controller: lngCtrl,
                            label: 'Longitude *',
                            hint: '80.1274',
                            prefixIcon: Icons.gps_fixed,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ErpTextField(
                            controller: orderCtrl,
                            label: 'Sequence #',
                            prefixIcon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ErpTextField(
                            controller: etaCtrl,
                            label: 'ETA',
                            hint: '08:15 AM',
                            prefixIcon: Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: ErpColors.textMuted),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.save_outlined, size: 16),
                label: Text('Save Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.primary,
                  foregroundColor: ErpColors.textPrimary,
                  minimumSize: const Size(120, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final latStr = latCtrl.text.trim();
                  final lngStr = lngCtrl.text.trim();

                  if (name.isEmpty || latStr.isEmpty || lngStr.isEmpty) {
                    _showSnackBar(
                      'Stop name, latitude and longitude are required.',
                      isError: true,
                    );
                    return;
                  }
                  final lat = double.tryParse(latStr);
                  final lng = double.tryParse(lngStr);
                  if (lat == null || lng == null) {
                    _showSnackBar(
                      'Latitude and longitude must be valid decimal numbers.',
                      isError: true,
                    );
                    return;
                  }
                  final order =
                      int.tryParse(orderCtrl.text.trim()) ?? nextOrder;
                  final eta =
                      etaCtrl.text.trim().isEmpty
                          ? '08:00 AM'
                          : etaCtrl.text.trim();

                  final targetStop = BusStopModel(
                    id: stop?.id ?? 0,
                    routeId: routeId,
                    stopName: name,
                    latitude: lat,
                    longitude: lng,
                    stopOrder: order,
                    estimatedArrivalTime: eta,
                    status: stop?.status ?? 'ACTIVE',
                  );

                  Navigator.pop(ctx);
                  try {
                    if (stop == null) {
                      await _busService.createStop(targetStop);
                    } else {
                      await _busService.updateStop(stop.id, targetStop);
                    }
                    _showSnackBar('Stop saved successfully!');
                    _loadStops(routeId);
                  } catch (e) {
                    _showSnackBar('Failed: $e', isError: true);
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _confirmDeleteStop(int routeId, BusStopModel stop) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Save Stop',
              style: GoogleFonts.outfit(
                color: ErpColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text('Delete "${stop.stopName}" from this route?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: ErpColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: ErpColors.textOnPrimary,
                  minimumSize: const Size(90, 40),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _busService.deleteStop(stop.id);
      _showSnackBar('Stop deleted.');
      _loadStops(routeId);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _confirmDeleteRoute(RouteModel route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Route?',
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${route.routeName}"?'),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will permanently delete the route and ALL its stops.',
                          style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: ErpColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: ErpColors.textOnPrimary,
                  minimumSize: const Size(90, 40),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete Route'),
              ),
            ],
          ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _busService.deleteRoute(route.id);
      _showSnackBar('Route deleted.');
      _loadRoutes();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : ErpColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            isActive
                ? ErpColors.textMuted
                : ErpColors.textMuted.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isActive
                  ? ErpColors.textMuted
                  : ErpColors.textMuted.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? ErpColors.textPrimary : ErpColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? ErpColors.textPrimary : ErpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteModel r) {
    final stops = _routeStops[r.id];
    final stopsLoading = stops == null;
    final stopCount = stops?.length ?? 0;

    return Card(
      color: ErpColors.bgWhite,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ErpColors.textPrimary),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          iconColor: ErpColors.primary,
          collapsedIconColor: ErpColors.textSecondary,
          title: Row(
            children: [
              // Route icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ErpColors.primary, ErpColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.route,
                  color: ErpColors.textOnPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.routeName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                    if (r.description.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        r.description,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: ErpColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              _buildStatusBadge(r.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 52, top: 4, bottom: 2),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: ErpColors.textPrimary,
                ),
                SizedBox(width: 4),
                stopsLoading
                    ? SizedBox(
                      width: 60,
                      height: 10,
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                    : Text(
                      '$stopCount stop${stopCount != 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: ErpColors.textMuted,
                      ),
                    ),
              ],
            ),
          ),
          children: [
            Divider(
              height: 1,
              color: ErpColors.textPrimary,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: "Route Stops" + Add Stop button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Route Stops',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: ErpColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showStopDialog(r.id),
                        icon: Icon(Icons.add_location_alt_outlined, size: 14),
                        label: Text(
                          'Add Stop',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ErpColors.textPrimary,
                          side: const BorderSide(color: ErpColors.textPrimary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Stops list or states
                  if (stopsLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                    )
                  else if (stops.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: ErpColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ErpColors.textOnPrimary.withValues(alpha: 0.1),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 32,
                            color: ErpColors.textOnPrimary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No stops found on this route.',
                            style: GoogleFonts.outfit(
                              color: ErpColors.textOnPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap Add Stop above to map a new stop.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: ErpColors.textOnPrimary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildStopsTimeline(r.id, stops),

                  SizedBox(height: 12),
                  const Divider(height: 1, color: ErpColors.textPrimary),
                  SizedBox(height: 10),

                  // Route action buttons
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionButton(
                        icon: Icons.map_rounded,
                        label: 'View Map',
                        color: ErpColors.textPrimary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => RouteMapDetailScreen(
                                    route: r,
                                    stops: stops ?? [],
                                  ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: ErpColors.textPrimary,
                        onTap: () => _showRouteDialog(route: r),
                      ),
                      SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        color: Colors.redAccent,
                        onTap: () => _confirmDeleteRoute(r),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsTimeline(int routeId, List<BusStopModel> stops) {
    // Sort by order to be safe
    final sorted = List<BusStopModel>.from(stops)
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    return Column(
      children: List.generate(sorted.length, (i) {
        final s = sorted[i];
        final isFirst = i == 0;
        final isLast = i == sorted.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline column
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    // Top connector
                    if (!isFirst)
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: ErpColors.textMuted,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 8),

                    // Stop dot
                    Container(
                      width: isFirst || isLast ? 18 : 12,
                      height: isFirst || isLast ? 18 : 12,
                      decoration: BoxDecoration(
                        color:
                            isFirst
                                ? ErpColors.textPrimary
                                : isLast
                                ? Colors.redAccent
                                : ErpColors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: ErpColors.bgWhite, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (isFirst
                                    ? ErpColors.textPrimary
                                    : isLast
                                    ? Colors.redAccent
                                    : ErpColors.textPrimary)
                                .withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // Bottom connector
                    if (!isLast)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: ErpColors.textMuted,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 8),
                  ],
                ),
              ),
              SizedBox(width: 14),

              // Stop card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ErpColors.bgWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isFirst
                              ? ErpColors.textMuted
                              : isLast
                              ? Colors.redAccent.withOpacity(0.3)
                              : ErpColors.textPrimary,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ErpColors.textMuted,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${s.stopOrder}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: ErpColors.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.stopName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: ErpColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit & delete
                          GestureDetector(
                            onTap: () => _showStopDialog(routeId, stop: s),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: ErpColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _confirmDeleteStop(routeId, s),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: ErpColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ETA: ${s.estimatedArrivalTime}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: ErpColors.textMuted,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.my_location,
                            size: 12,
                            color: ErpColors.textMuted.withOpacity(0.7),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '(${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)})',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: ErpColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        foregroundColor: ErpColors.textOnPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Routes & Stops',
              style: GoogleFonts.outfit(
                color: ErpColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (!_isLoading && _routes.isNotEmpty)
              Text(
                '${_routes.length} route${_routes.length != 1 ? 's' : ''} configured',
                style: GoogleFonts.outfit(
                  color: ErpColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: ErpColors.textSecondary),
            onPressed: _loadRoutes,
            tooltip: 'Refresh',
          ),
          SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showRouteDialog(),
              icon: Icon(Icons.add, size: 16, color: ErpColors.textPrimary),
              label: Text(
                'No routes found.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ErpColors.textPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ErpColors.accent,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _RoutesSkeleton();
    }

    if (_error != null) {
      return ErpErrorState(
        message: 'We could not retrieve routes and stops right now.',
        onRetry: _loadRoutes,
      );
    }

    if (_routes.isEmpty) {
      return const ErpEmptyState(
        message: 'No routes configured',
        subtitle:
            'Create a route to begin managing stops and transport assignments.',
        icon: Icons.route_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoutes,
      color: ErpColors.primary,
      backgroundColor: ErpColors.bgWhite,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _routes.length,
        itemBuilder: (_, i) => _buildRouteCard(_routes[i]),
      ),
    );
  }
}

class _RoutesSkeleton extends StatelessWidget {
  const _RoutesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
