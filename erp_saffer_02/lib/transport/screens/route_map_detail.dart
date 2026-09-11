import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_model.dart';
import '../models/bus_stop_model.dart';

class RouteMapDetailScreen extends StatefulWidget {
  final RouteModel route;
  final List<BusStopModel> stops;

  const RouteMapDetailScreen({
    Key? key,
    required this.route,
    required this.stops,
  }) : super(key: key);

  @override
  State<RouteMapDetailScreen> createState() => _RouteMapDetailScreenState();
}

class _RouteMapDetailScreenState extends State<RouteMapDetailScreen> {
  final MapController _mapController = MapController();
  final LatLng _collegeCoords = const LatLng(12.8794, 80.0818);
  int? _selectedStopId;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnStop(double lat, double lng, int stopId) {
    setState(() {
      _selectedStopId = stopId;
    });
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> routePoints = [];
    final sortedStops = List<BusStopModel>.from(widget.stops)
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    for (var s in sortedStops) {
      routePoints.add(LatLng(s.latitude, s.longitude));
    }
    // Final end point is college campus
    routePoints.add(_collegeCoords);

    double defaultLat = _collegeCoords.latitude;
    double defaultLng = _collegeCoords.longitude;
    if (sortedStops.isNotEmpty) {
      defaultLat = sortedStops.first.latitude;
      defaultLng = sortedStops.first.longitude;
    }

    return Scaffold(
      backgroundColor: ErpColors.primary,
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(defaultLat, defaultLng),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.erp.college.bus',
              ),
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    // Outer border line for premium look
                    Polyline(
                      points: routePoints,
                      strokeWidth: 6.0,
                      color: Colors.amber.shade700,
                    ),
                    // Inner indicator line
                    Polyline(
                      points: routePoints,
                      strokeWidth: 3.5,
                      color: ErpColors.textOnPrimary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Intermediate points
                  ...sortedStops.map((stop) {
                    final isSelected = _selectedStopId == stop.id;
                    final isFirst =
                        sortedStops.isNotEmpty &&
                        sortedStops.first.id == stop.id;

                    return Marker(
                      point: LatLng(stop.latitude, stop.longitude),
                      width: isSelected ? 75 : 55,
                      height: isSelected ? 75 : 55,
                      child: GestureDetector(
                        onTap: () {
                          _centerOnStop(stop.latitude, stop.longitude, stop.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.amber.shade700
                                          : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.blue.shade700,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFirst
                                      ? Icons.play_arrow_rounded
                                      : Icons.circle,
                                  color:
                                      isFirst
                                          ? Colors.green.shade600
                                          : (isSelected
                                              ? Colors.white
                                              : Colors.blue.shade700),
                                  size: isSelected ? 24 : 12,
                                ),
                              ),
                              SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: ErpColors.bgWhite,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: ErpColors.textMuted,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  stop.stopName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isSelected
                                            ? Colors.amber.shade900
                                            : ErpColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Live Bus Location (Simulated at first stop or college)
                  Marker(
                    point:
                        routePoints.isNotEmpty
                            ? routePoints.first
                            : _collegeCoords,
                    width: 70,
                    height: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.amber.shade400,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Final point: College Marker
                  Marker(
                    point: _collegeCoords,
                    width: 75,
                    height: 75,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStopId = 999999;
                        });
                        _mapController.move(_collegeCoords, 15.0);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ErpColors.textOnPrimary,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: ErpColors.textOnPrimary,
                              size: 22,
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '---',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: ErpColors.textOnPrimary,
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

          // 2. Custom header bar (Top Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ErpColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: ErpColors.textOnPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.route.routeName,
                          style: GoogleFonts.outfit(
                            color: ErpColors.textOnPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.route.description.isNotEmpty
                              ? widget.route.description
                              : 'No description provided.',
                          style: GoogleFonts.outfit(
                            color: ErpColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ErpColors.textMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ErpColors.textOnPrimary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.route.status,
                      style: GoogleFonts.outfit(
                        color: ErpColors.textOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Rapido UI Bottom Sheet Panel
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: ErpColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // Scroll Handle Bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: ErpColors.textMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Quick Overview Header Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '---',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: ErpColors.textOnPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${sortedStops.length} Checkpoints · Terminating at College',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: ErpColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: ErpColors.textMuted,
                                foregroundColor: ErpColors.textOnPrimary,
                              ),
                              icon: Icon(Icons.my_location),
                              onPressed: () {
                                if (sortedStops.isNotEmpty) {
                                  _mapController.move(
                                    LatLng(
                                      sortedStops.first.latitude,
                                      sortedStops.first.longitude,
                                    ),
                                    13.0,
                                  );
                                } else {
                                  _mapController.move(_collegeCoords, 13.0);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Divider(color: Colors.black12, thickness: 1),
                      ),

                      // Stops Timeline List
                      if (sortedStops.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No stops added to this route yet.',
                              style: GoogleFonts.outfit(
                                fontStyle: FontStyle.italic,
                                color: ErpColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              sortedStops.length +
                              1, // list of stops + Terminal Campus Stop
                          itemBuilder: (context, index) {
                            final isLast = index == sortedStops.length;

                            // Final target is always College
                            if (isLast) {
                              final isSelected = _selectedStopId == 999999;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedStopId = 999999;
                                  });
                                  _mapController.move(_collegeCoords, 15.0);
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bouncing dot & line
                                    Column(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: ErpColors.textOnPrimary,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.school_rounded,
                                            color: ErpColors.textOnPrimary,
                                            size: 11,
                                          ),
                                        ),
                                        // Terminal stop has no extension line
                                      ],
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'COLLEGE CAMPUS (Final Depot)',
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isSelected
                                                        ? Colors.redAccent
                                                        : ErpColors
                                                            .textOnPrimary,
                                              ),
                                            ),
                                            Text(
                                              'Coordinates: ${_collegeCoords.latitude}, ${_collegeCoords.longitude}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: ErpColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final stop = sortedStops[index];
                            final isStopSelected = _selectedStopId == stop.id;
                            final isFirstStop = index == 0;

                            return InkWell(
                              onTap: () {
                                _centerOnStop(
                                  stop.latitude,
                                  stop.longitude,
                                  stop.id,
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stop Indicator Timeline Graphics
                                  Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: isStopSelected ? 24 : 20,
                                        height: isStopSelected ? 24 : 20,
                                        decoration: BoxDecoration(
                                          color:
                                              isStopSelected
                                                  ? Colors.amber.shade700
                                                  : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isStopSelected
                                                    ? Colors.white
                                                    : Colors.blue.shade700,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${stop.stopOrder}',
                                            style: GoogleFonts.outfit(
                                              color:
                                                  isStopSelected
                                                      ? Colors.white
                                                      : Colors.blue.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Connector line
                                      Container(
                                        width: 2.5,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                              isStopSelected
                                                  ? Colors.amber.shade700
                                                  : ErpColors.textOnPrimary
                                                      .withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 14),

                                  // Checkpoint Texts
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  stop.stopName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        isStopSelected
                                                            ? Colors
                                                                .amber
                                                                .shade800
                                                            : ErpColors
                                                                .textOnPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // ETA Badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isFirstStop
                                                          ? Colors.green
                                                              .withOpacity(0.12)
                                                          : ErpColors
                                                              .textOnPrimary
                                                              .withOpacity(
                                                                0.06,
                                                              ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  stop.estimatedArrivalTime,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        isFirstStop
                                                            ? Colors
                                                                .green
                                                                .shade800
                                                            : ErpColors
                                                                .textOnPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Coords: ${stop.latitude.toStringAsFixed(5)}, ${stop.longitude.toStringAsFixed(5)}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: ErpColors.textMuted,
                                            ),
                                          ),
                                          if (isFirstStop)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Text(
                                                '⚡ Initial Start Stop',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
