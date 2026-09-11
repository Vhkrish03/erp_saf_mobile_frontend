import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/student_transport_assignment_model.dart';
import '../models/bus_stop_model.dart';
import '../services/bus_service.dart';
import 'student_live_tracking.dart';

class StudentTransportDashboardScreen extends StatefulWidget {
  final String studentId;
  const StudentTransportDashboardScreen({Key? key, required this.studentId})
    : super(key: key);

  @override
  State<StudentTransportDashboardScreen> createState() =>
      _StudentTransportDashboardScreenState();
}

class _StudentTransportDashboardScreenState
    extends State<StudentTransportDashboardScreen> {
  final BusService _busService = BusService();
  StudentTransportAssignmentModel? _assignment;
  List<BusStopModel> _routeStops = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransportInfo();
  }

  Future<void> _loadTransportInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assign = await _busService.getStudentTransportProfile(
        widget.studentId,
        "STUDENT",
      );
      if (assign != null) {
        final stops = await _busService.getMyBusStops(
          widget.studentId,
          "STUDENT",
        );
        setState(() {
          _assignment = assign;
          _routeStops = stops;
          _isLoading = false;
        });
      } else {
        setState(() {
          _assignment = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'We could not retrieve transport details right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        title: Text(
          'My Transport Dashboard',
          style: ErpTypography.titleLarge.copyWith(color: ErpColors.textOnPrimary),
        ),
      ),
      body:
          _isLoading
              ? const _TransportSkeleton()
              : _errorMessage != null
              ? _buildErrorView()
              : _assignment == null
              ? _buildNotAssignedView()
              : _buildAssignedView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: ErpColors.danger, size: 48),
            SizedBox(height: 12),
            Text(
              'Unable to load transport details',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ErpColors.primary),
              onPressed: _loadTransportInfo,
              child: Text(
                'Try Again',
style: GoogleFonts.outfit(color: ErpColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAssignedView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ErpColors.textMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_outlined,
                size: 80,
                color: ErpColors.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Retry',
style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ErpColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'No Bus Assigned',
style: GoogleFonts.outfit(color: ErpColors.textMuted, height: 1.4),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ErpColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _loadTransportInfo,
              icon: Icon(Icons.refresh, color: ErpColors.textPrimary),
              label: Text(
                'Contact admin for route assignment',
style: GoogleFonts.outfit(color: ErpColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedView() {
    final assign = _assignment!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Transit Pass Card
          Card(
            color: ErpColors.bgWhite,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assign.bus.busNumber,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: ErpColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Reg No: ${assign.bus.registrationNumber}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: ErpColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ErpColors.textMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Refresh',
style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: ErpColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildPassDetailRow('Your Route', assign.route.routeName),
                  _buildPassDetailRow('Description', assign.route.description),
                  _buildPassDetailRow(
                    'Pickup Stop',
                    assign.pickupStop?.stopName ?? 'Not specified',
                  ),
                  _buildPassDetailRow(
                    'Pickup Time',
                    assign.pickupStop?.estimatedArrivalTime ?? 'N/A',
                  ),
                  _buildPassDetailRow(
                    'Drop Stop',
                    assign.dropStop?.stopName ?? 'Not specified',
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ErpColors.primary,
                        child: Icon(Icons.person, color: ErpColors.textPrimary),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assign.bus.driver?.name ?? 'Assigned Driver',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: ErpColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Phone: ${assign.bus.driver?.phone ?? "No phone listed"}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: ErpColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Track My Bus CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ErpColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => StudentLiveTrackingScreen(
                          studentId: widget.studentId,
                          assignment: assign,
                        ),
                  ),
                );
              },
              icon: Icon(Icons.location_on, color: ErpColors.textPrimary),
              label: Text(
                'Refresh',
style: GoogleFonts.outfit(
                  color: ErpColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(height: 28),

          // Route timeline visualization
          Text(
            'Refresh',
style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: ErpColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          if (_routeStops.isEmpty)
            Text(
              'Refresh',
style: GoogleFonts.outfit(
                fontStyle: FontStyle.italic,
                color: ErpColors.textMuted,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _routeStops.length,
              itemBuilder: (context, idx) {
                final stop = _routeStops[idx];
                final isMyPickup = assign.pickupStop?.id == stop.id;
                final isMyDrop = assign.dropStop?.id == stop.id;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color:
                                (isMyPickup || isMyDrop)
                                    ? ErpColors.textPrimary
                                    : ErpColors.textPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: ErpColors.textPrimary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (idx != _routeStops.length - 1)
                          Container(
                            width: 2,
                            height: 44,
                            color: ErpColors.textMuted,
                          ),
                      ],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                stop.stopName,
                                style: GoogleFonts.outfit(
                                  fontWeight:
                                      (isMyPickup || isMyDrop)
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                  color:
                                      (isMyPickup || isMyDrop)
                                          ? ErpColors.textPrimary
                                          : ErpColors.textPrimary,
                                ),
                              ),
                              if (isMyPickup) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ErpColors.textPrimary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Refresh',
style: GoogleFonts.outfit(
                                      color: ErpColors.textPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (isMyDrop) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ErpColors.textPrimary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Refresh',
style: GoogleFonts.outfit(
                                      color: ErpColors.textPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'ETA: ${stop.estimatedArrivalTime}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: ErpColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ErpColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 13, color: ErpColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportSkeleton extends StatelessWidget {
  const _TransportSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 140, radius: 16),
        SizedBox(height: 16),
        ErpSkeleton(height: 96, radius: 16),
        SizedBox(height: 16),
        ErpSkeleton(height: 180, radius: 16),
      ],
    );
  }
}

