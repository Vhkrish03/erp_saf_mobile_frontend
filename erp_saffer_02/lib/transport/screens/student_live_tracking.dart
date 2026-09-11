import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/student_transport_assignment_model.dart';
import '../models/bus_location_model.dart';
import '../models/bus_stop_model.dart';
import '../services/bus_service.dart';

class StudentLiveTrackingScreen extends StatefulWidget {
  final String studentId;
  final StudentTransportAssignmentModel assignment;

  const StudentLiveTrackingScreen({
    Key? key,
    required this.studentId,
    required this.assignment,
  }) : super(key: key);

  @override
  State<StudentLiveTrackingScreen> createState() =>
      _StudentLiveTrackingScreenState();
}

class _StudentLiveTrackingScreenState extends State<StudentLiveTrackingScreen> {
  final BusService _busService = BusService();
  final MapController _mapController = MapController();

  BusLocationModel? _currentLocation;
  List<BusStopModel> _stops = [];
  bool _isLoading = true;
  String? _trackerError;

  Timer? _refreshTimer;

  // College main campus coordinate reference (defaults if not in route)
  final LatLng _collegeCoords = const LatLng(12.8794, 80.0818);

  @override
  void initState() {
    super.initState();
    _loadStopsAndStartTracking();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadStopsAndStartTracking() async {
    try {
      final list = await _busService.getMyBusStops(widget.studentId, "STUDENT");
      setState(() {
        _stops = list;
      });
    } catch (e) {
      debugPrint('Error loading stops: $e');
    }

    // Fetch initial location
    await _pollTrackerLocation();

    // Start auto refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollTrackerLocation();
    });

    setState(() => _isLoading = false);
  }

  Future<void> _pollTrackerLocation() async {
    try {
      final loc = await _busService.getMyBusLocation(
        widget.studentId,
        "STUDENT",
      );
      setState(() {
        _currentLocation = loc;
        _trackerError = null;
      });

      // Animate map view to center the bus if they are tracking
      try {
        _mapController.move(LatLng(loc.latitude, loc.longitude), 14.0);
      } catch (e) {
        debugPrint('MapController not initialized yet: $e');
      }
    } catch (e) {
      setState(() {
        _trackerError = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collect coordinates lists for drawing polylines route paths
    final List<LatLng> routePoints = [];
    for (var s in _stops) {
      routePoints.add(LatLng(s.latitude, s.longitude));
    }
    // Add college campus as terminal point if not empty
    if (routePoints.isNotEmpty) {
      routePoints.add(_collegeCoords);
    }

    final double centerLat =
        _stops.isNotEmpty ? _stops.first.latitude : _collegeCoords.latitude;
    final double centerLng =
        _stops.isNotEmpty ? _stops.first.longitude : _collegeCoords.longitude;

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        title: Text(
          'Track ${widget.assignment.bus.busNumber}',
          style: GoogleFonts.outfit(
            color: ErpColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ErpColors.textPrimary),
            onPressed: () {
              setState(() => _isLoading = true);
              _pollTrackerLocation().then(
                (_) => setState(() => _isLoading = false),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ErpColors.primary),
              )
              : Stack(
                children: [
                  // Interactive OpenStreetMap Layer
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          _currentLocation != null
                              ? LatLng(
                                _currentLocation!.latitude,
                                _currentLocation!.longitude,
                              )
                              : LatLng(centerLat, centerLng),
                      initialZoom: 13.5,
                      onMapReady: () {
                        if (_currentLocation != null) {
                          try {
                            _mapController.move(
                              LatLng(
                                _currentLocation!.latitude,
                                _currentLocation!.longitude,
                              ),
                              14.0,
                            );
                          } catch (e) {
                            debugPrint(
                              'MapController move failed onMapReady: $e',
                            );
                          }
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.erp.college.bus',
                      ),

                      // Route Polyline connection line
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 4.5,
                              color: ErpColors.textMuted,
                              borderColor: ErpColors.textPrimary,
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),

                      // Markers Overlay (Stops + Bus + Campus)
                      MarkerLayer(
                        markers: [
                          // 1. Route Stops markers
                          ..._stops.map((stop) {
                            final isMyPickup =
                                widget.assignment.pickupStop?.id == stop.id;
                            final isMyDrop =
                                widget.assignment.dropStop?.id == stop.id;
                            return Marker(
                              point: LatLng(stop.latitude, stop.longitude),
                              width: 60,
                              height: 60,
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (context) => Container(
                                          decoration: const BoxDecoration(
                                            color: ErpColors.primary,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor: ErpColors.bgWhite
                                                        .withOpacity(0.1),
                                                    child: Text(
                                                      '${stop.stopOrder}',
                                                      style: GoogleFonts.outfit(
                                                        color: ErpColors.textPrimary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          stop.stopName,
                                                          style:
                                                              GoogleFonts.outfit(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                                color:
                                                                    ErpColors.textPrimary,
                                                              ),
                                                        ),
                                                        if (isMyPickup)
                                                          Text(
                                                            '---',
                                                            style:
                                                                GoogleFonts.outfit(
                                                                  color:
                                                                      ErpColors.textPrimary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        if (isMyDrop)
                                                          Text(
                                                            '---',
                                                            style:
                                                                GoogleFonts.outfit(
                                                                  color:
                                                                      ErpColors.textPrimary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 24),
                                              _buildDetailRow(
                                                Icons.access_time,
                                                'Scheduled Arrival',
                                                stop.estimatedArrivalTime,
                                              ),
                                              _buildDetailRow(
                                                Icons.pin_drop,
                                                'Coordinates',
                                                '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}',
                                              ),
                                              _buildDetailRow(
                                                Icons.route_outlined,
                                                'Status',
                                                stop.status,
                                              ),
                                              SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                  );
                                },
                                child: Tooltip(
                                  message: stop.stopName,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isMyPickup
                                            ? Icons.location_on
                                            : Icons.location_on_outlined,
                                        color:
                                            isMyPickup
                                                ? ErpColors.textPrimary
                                                : ErpColors.textPrimary,
                                        size: isMyPickup ? 32 : 24,
                                      ),
                                      Text(
                                        stop.stopName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isMyPickup
                                                  ? ErpColors.textPrimary
                                                  : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          // 2. College campus marker
                          Marker(
                            point: _collegeCoords,
                            width: 70,
                            height: 70,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (context) => Container(
                                        decoration: const BoxDecoration(
                                          color: ErpColors.primary,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: Colors.redAccent
                                                      .withOpacity(0.1),
                                                  child: Icon(
                                                    Icons.school,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'College Campus Destination',
                                                    style: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: ErpColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 24),
                                            _buildDetailRow(
                                              Icons.navigation,
                                              'Campus Center',
                                              'Chinna Kolambakkam, Maduranthakam Taluk, Chengalpattu District',
                                            ),
                                            _buildDetailRow(
                                              Icons.pin_drop,
                                              'Coordinates',
                                              '${_collegeCoords.latitude}, ${_collegeCoords.longitude}',
                                            ),
                                            SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                  Text(
                                    'COLLEGE CAMPUS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 3. Live bus location marker
                          if (_currentLocation != null)
                            Marker(
                              point: LatLng(
                                _currentLocation!.latitude,
                                _currentLocation!.longitude,
                              ),
                              width: 65,
                              height: 65,
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (context) => Container(
                                          decoration: const BoxDecoration(
                                            color: ErpColors.primary,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor: ErpColors.bgWhite
                                                        .withOpacity(0.2),
                                                    child: Icon(
                                                      Icons.directions_bus,
                                                      color: ErpColors.textPrimary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          widget
                                                              .assignment
                                                              .bus
                                                              .busNumber,
                                                          style:
                                                              GoogleFonts.outfit(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                                color:
                                                                    ErpColors.textPrimary,
                                                              ),
                                                        ),
                                                        Text(
                                                          'Driver: ${widget.assignment.bus.driver?.name ?? "N/A"}',
                                                          style:
                                                              GoogleFonts.outfit(
                                                                color:
                                                                    ErpColors.textMuted,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 24),
                                              _buildDetailRow(
                                                Icons.speed,
                                                'Current Speed',
                                                '${_currentLocation!.speed.toStringAsFixed(0)} km/h',
                                              ),
                                              _buildDetailRow(
                                                Icons.explore,
                                                'Heading',
                                                '${_currentLocation!.heading.toStringAsFixed(0)}°',
                                              ),
                                              _buildDetailRow(
                                                Icons.check_circle_outline,
                                                'Broadcast Status',
                                                _currentLocation!.status
                                                    .replaceAll('_', ' '),
                                              ),
                                              _buildDetailRow(
                                                Icons.pin_drop,
                                                'Coordinates',
                                                '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                                              ),
                                              SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: ErpColors.textPrimary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.directions_bus,
                                        color: ErpColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      color: ErpColors.textPrimary,
                                      child: Text(
                                        widget.assignment.bus.busNumber,
                                        style: GoogleFonts.outfit(
                                          color: ErpColors.textPrimary,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Top Offline Warning Banner
                  if (_trackerError != null)
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .signal_wifi_connected_no_internet_4_outlined,
                              color: ErpColors.textPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'GPS Tracker Connection Failure:\n$_trackerError \n(Showing last known route settings)',
                                style: GoogleFonts.outfit(
                                  color: ErpColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bottom floating dynamic panel updating in real-time
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Card(
                      color: ErpColors.bgWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.assignment.bus.busNumber,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: ErpColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      widget.assignment.route.routeName,
                                      style: GoogleFonts.outfit(
                                        color: ErpColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                if (_currentLocation != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _currentLocation!.status == 'ON_ROUTE'
                                              ? Colors.green.withOpacity(0.12)
                                              : ErpColors.textMuted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _currentLocation!.status.replaceAll(
                                        '_',
                                        ' ',
                                      ),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color:
                                            _currentLocation!.status ==
                                                    'ON_ROUTE'
                                                ? Colors.green
                                                : ErpColors.textPrimary,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '---',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTelemetryWidget(
                                  icon: Icons.speed,
                                  value:
                                      _currentLocation != null
                                          ? '${_currentLocation!.speed.toStringAsFixed(0)} km/h'
                                          : '0 km/h',
                                  label: 'Mock Speed',
                                ),
                                _buildTelemetryWidget(
                                  icon: Icons.explore,
                                  value:
                                      _currentLocation != null
                                          ? '${_currentLocation!.heading.toStringAsFixed(0)}°'
                                          : 'N/A',
                                  label: 'Heading',
                                ),
                                _buildTelemetryWidget(
                                  icon: Icons.person_outline,
                                  value:
                                      widget.assignment.bus.driver?.name ??
                                      'No Driver',
                                  label: 'Driver',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTelemetryWidget({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: ErpColors.textPrimary, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: ErpColors.textPrimary,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(color: ErpColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: ErpColors.textPrimary, size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
              color: ErpColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                color: ErpColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

