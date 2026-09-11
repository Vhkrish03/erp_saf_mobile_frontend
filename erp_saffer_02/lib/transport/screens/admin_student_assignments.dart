import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../../services/admin_api_service.dart';
import '../../models/student.dart';
import '../models/bus_model.dart';
import '../models/bus_stop_model.dart';
import '../models/student_transport_assignment_model.dart';
import '../services/bus_service.dart';

class AdminStudentAssignmentsScreen extends StatefulWidget {
  const AdminStudentAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStudentAssignmentsScreen> createState() =>
      _AdminStudentAssignmentsScreenState();
}

class _AssignmentsSkeleton extends StatelessWidget {
  const _AssignmentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 96, radius: 16),
        SizedBox(height: 12),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _AdminStudentAssignmentsScreenState
    extends State<AdminStudentAssignmentsScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  final BusService _busService = BusService();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  List<BusModel> _buses = [];
  // Typed as Map so selYear!['id'] and dropdown equality work correctly
  List<Map<String, dynamic>> _academicYears = [];
  List<StudentTransportAssignmentModel> _activeAssignments = [];

  bool _isLoading = true;

  // ── Filters ────────────────────────────────────────────────────
  String _searchQuery = '';
  String? _selectedDept;
  String? _selectedYear;
  String? _selectedResidency;
  String? _selectedTransportStatus;

  List<String> get _depts =>
      (_allStudents.map((s) => s.department.trim()).toSet().toList()..sort());
  List<String> get _years =>
      (_allStudents.map((s) => s.year.trim()).toSet().toList()..sort());

  // ── Init ───────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final students = await _adminApiService.getAllStudents();
      final buses = await _busService.getBuses();

      // FIX 1: getAssignments() already returns List<StudentTransportAssignmentModel>.
      // Storing it as List<dynamic> then calling .fromJson() on each element
      // caused: "StudentTransportAssignment is not a subtype of Map<String,dynamic>".
      List<StudentTransportAssignmentModel> assignments = [];
      try {
        assignments = await _busService.getAssignments();
      } catch (e) {
        debugPrint('Assignments load error (non-fatal): $e');
      }

      // FIX 2: Cast to List<Map<String,dynamic>> so that:
      //   • selYear!['id'] access works at runtime
      //   • DropdownMenuItem value equality works (same Map instance == same Map)
      List<Map<String, dynamic>> years = [];
      try {
        final raw = await _adminApiService.getAllAcademicYears();
        years = raw.whereType<Map<String, dynamic>>().toList();
        // Sort: active years first, then by name descending
        years.sort((a, b) {
          final aActive = a['active'] == true || a['isActive'] == true;
          final bActive = b['active'] == true || b['isActive'] == true;
          if (aActive != bActive) return aActive ? -1 : 1;
          return (b['yearName'] ?? '').compareTo(a['yearName'] ?? '');
        });
      } catch (e) {
        debugPrint('Academic years load error (non-fatal): $e');
        // Keep years empty — user will see an informative message in the dialog
      }

      if (!mounted) return;
      setState(() {
        _allStudents = students;
        _buses =
            buses.where((b) => b.status.toUpperCase() == 'ACTIVE').toList();
        _activeAssignments =
            assignments; // already the right type — no re-parsing
        _academicYears = years;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Filter logic ───────────────────────────────────────────────

  String _n(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  void _applyFilters() {
    setState(() {
      _filteredStudents =
          _allStudents.where((s) {
            // Search
            final q = _searchQuery.toLowerCase();
            final matchSearch =
                q.isEmpty ||
                s.name.toLowerCase().contains(q) ||
                s.rollNumber.toLowerCase().contains(q) ||
                s.id.toString().contains(q);

            // Dept — contains match so "CSE" matches "CSE Engineering" etc.
            final matchDept =
                _selectedDept == null ||
                _n(s.department) == _n(_selectedDept!) ||
                _n(s.department).contains(_n(_selectedDept!));

            // Year — digit extraction so "4" matches "4th", "IV" partial fallback
            bool matchYear = _selectedYear == null;
            if (!matchYear) {
              final sv = _n(s.year);
              final sd = _digits(s.year);
              final fd = _digits(_selectedYear!);
              matchYear =
                  sv == _n(_selectedYear!) ||
                  sv.contains(_n(_selectedYear!)) ||
                  (sd.isNotEmpty && fd.isNotEmpty && sd == fd);
            }

            // Residency
            final res =
                s.residencyType.toUpperCase().contains('HOSTEL')
                    ? 'HOSTELLER'
                    : 'DAY_SCHOLAR';
            final matchRes =
                _selectedResidency == null || res == _selectedResidency;

            // Transport status (compare IDs as strings)
            final sid = s.id.toString().trim();
            final isAssigned = _activeAssignments.any(
              (a) =>
                  a.student.id.toString().trim() == sid &&
                  a.status.toUpperCase() == 'ACTIVE',
            );
            bool matchTransport = _selectedTransportStatus == null;
            if (!matchTransport) {
              matchTransport =
                  _selectedTransportStatus == 'ASSIGNED'
                      ? isAssigned
                      : !isAssigned;
            }

            return matchSearch &&
                matchDept &&
                matchYear &&
                matchRes &&
                matchTransport;
          }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDept = null;
      _selectedYear = null;
      _selectedResidency = null;
      _selectedTransportStatus = null;
    });
    _applyFilters();
  }

  bool get _hasFilters =>
      _searchQuery.isNotEmpty ||
      _selectedDept != null ||
      _selectedYear != null ||
      _selectedResidency != null ||
      _selectedTransportStatus != null;

  // ── Assignment lookup ──────────────────────────────────────────

  StudentTransportAssignmentModel? _assignmentFor(String studentId) {
    final sid = studentId.trim();
    try {
      return _activeAssignments.firstWhere(
        (a) =>
            a.student.id.toString().trim() == sid &&
            a.status.toUpperCase() == 'ACTIVE',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Today string ───────────────────────────────────────────────

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Assign dialog ──────────────────────────────────────────────

  void _showAssignDialog(Student student) {
    if (student.residencyType.toUpperCase().contains('HOSTEL')) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Ineligible'),
              content: Text(
                '${student.name} is a Hosteller and cannot be assigned bus transport.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final currentAssign = _assignmentFor(student.id);

    BusModel? selBus;
    if (currentAssign != null && _buses.isNotEmpty) {
      selBus = _buses.firstWhere(
        (b) => b.id == currentAssign.bus.id,
        orElse: () => _buses.first,
      );
    } else if (_buses.isNotEmpty) {
      selBus = _buses.first;
    }

    // ── Dialog-local mutable state ─────────────────────────────
    // We keep these as local variables and use StatefulBuilder's `set()`
    // to rebuild only the dialog (not the whole screen).
    List<BusStopModel> stops = [];
    BusStopModel? selPickup;
    BusStopModel? selDrop;
    Map<String, dynamic>? selYear =
        _academicYears.isNotEmpty ? _academicYears.first : null;

    // FIX: use a dedicated boolean so we can distinguish
    //   • null route     → show warning, never fetch
    //   • loading        → _stopsLoading = true, show spinner
    //   • loaded (empty) → _stopsLoading = false, stops == []
    //   • loaded (data)  → _stopsLoading = false, stops.isNotEmpty
    bool _stopsLoading = false;
    // Track which routeId we last requested so a bus-change
    // does not trigger double-fetches.
    int? _loadedForRouteId;

    void loadStopsFor(int routeId, StateSetter set) {
      if (_loadedForRouteId == routeId) return; // already loading/loaded
      _loadedForRouteId = routeId;
      set(() {
        _stopsLoading = true;
        stops = [];
        selPickup = null;
        selDrop = null;
      });
      _busService
          .getStops(routeId)
          .then((list) {
            if (!mounted) return;
            set(() {
              _stopsLoading = false;
              stops = list;
              if (list.isNotEmpty) {
                selPickup =
                    currentAssign?.pickupStop != null
                        ? list.firstWhere(
                          (s) => s.id == currentAssign!.pickupStop!.id,
                          orElse: () => list.first,
                        )
                        : list.first;
                selDrop =
                    currentAssign?.dropStop != null
                        ? list.firstWhere(
                          (s) => s.id == currentAssign!.dropStop!.id,
                          orElse: () => list.last,
                        )
                        : list.last;
              }
            });
          })
          .catchError((e) {
            if (!mounted) return;
            set(() {
              _stopsLoading = false;
              stops = []; // treat error as "no stops"
            });
            debugPrint('Error loading stops for route $routeId: $e');
          });
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, set) {
              final route = selBus?.route;

              // Trigger a one-shot fetch whenever the selected bus has a route
              // that we haven't loaded yet.  This runs inside the builder but
              // is guarded by _loadedForRouteId, so it fires EXACTLY ONCE per
              // distinct routeId, not on every rebuild.
              if (route != null && _loadedForRouteId != route.id) {
                // Use Future.microtask to avoid calling set() during build.
                Future.microtask(() => loadStopsFor(route.id, set));
              }

              final canSave =
                  selBus != null &&
                  route != null &&
                  !_stopsLoading &&
                  selPickup != null &&
                  selDrop != null &&
                  selYear != null;

              return AlertDialog(
                backgroundColor: ErpColors.bg,
                surfaceTintColor: Colors.transparent,
                titlePadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                actionsPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: ErpColors.bgWhite,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(bottom: BorderSide.none),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentAssign == null
                            ? Icons.directions_bus_rounded
                            : Icons.edit_road_rounded,
                        color: ErpColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentAssign == null
                            ? "Assign Transport"
                            : "Edit Assignment",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: ErpColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Student header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: ErpColors.bgWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: ErpColors.textPrimary,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${student.name}  (${student.rollNumber})',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 24),

                        // ── Bus picker ────────────────────────────
                        DropdownButtonFormField<BusModel>(
                          isExpanded: true,
                          value: selBus,
                          decoration: InputDecoration(
                            labelText: 'Bus',
                            prefixIcon: Icon(Icons.directions_bus_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: ErpColors.bg,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          dropdownColor: ErpColors.bgWhite,
                          items:
                              _buses
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(
                                        '${b.busNumber}  ·  ${b.route?.routeName ?? "No route"}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            set(() {
                              selBus = val;
                              // Reset stop state for the new bus
                              stops = [];
                              selPickup = null;
                              selDrop = null;
                              _stopsLoading = false;
                              _loadedForRouteId = null; // allow re-fetch
                            });
                          },
                        ),
                        SizedBox(height: 12),

                        // ── Route info / stops ────────────────────
                        if (route != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.route,
                                  size: 14,
                                  color: ErpColors.textPrimary,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Route: ${route.routeName}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ErpColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),

                          // Loading spinner  (only while fetching)
                          if (_stopsLoading)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    color: ErpColors.textPrimary,
                                    backgroundColor: ErpColors.bg,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Loading route stops…',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: ErpColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // Loaded but empty
                          else if (stops.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: ErpColors.textPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This route has no stops yet. Add stops in Routes & Stops first.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: ErpColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // Loaded with data — show pickup + drop pickers
                          else ...[
                            DropdownButtonFormField<BusStopModel>(
                              isExpanded: true,
                              value: selPickup,
                              decoration: InputDecoration(
                                labelText: 'Pickup Stop',
                                prefixIcon: Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: ErpColors.textPrimary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: ErpColors.bg,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              dropdownColor: ErpColors.bgWhite,
                              items:
                                  stops
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            '${s.stopOrder}. ${s.stopName}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => set(() => selPickup = v),
                            ),
                            SizedBox(height: 12),
                            DropdownButtonFormField<BusStopModel>(
                              isExpanded: true,
                              value: selDrop,
                              decoration: InputDecoration(
                                labelText: 'Drop Stop',
                                prefixIcon: Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: ErpColors.bg,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              dropdownColor: ErpColors.bgWhite,
                              items:
                                  stops
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            '${s.stopOrder}. ${s.stopName}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => set(() => selDrop = v),
                            ),
                          ],
                        ] else
                          // No route on this bus
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This bus has no route assigned. Assign a route to this bus first.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 12),

                        // ── Academic year ─────────────────────────
                        if (_academicYears.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No academic years found. Please configure academic years in the system first.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<Map<String, dynamic>>(
                            isExpanded: true,
                            value: selYear,
                            decoration: InputDecoration(
                              labelText: 'Academic Year *',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: ErpColors.bg,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            dropdownColor: ErpColors.bgWhite,
                            items:
                                _academicYears
                                    .map(
                                      (y) => DropdownMenuItem<
                                        Map<String, dynamic>
                                      >(
                                        value: y,
                                        child: Row(
                                          children: [
                                            if (y['active'] == true ||
                                                y['isActive'] == true)
                                              Container(
                                                width: 7,
                                                height: 7,
                                                margin: const EdgeInsets.only(
                                                  right: 7,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color:
                                                      ErpColors.textOnPrimary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                y['yearName']?.toString() ?? '',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => set(() => selYear = v),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (currentAssign != null)
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _busService.deactivateAssignment(
                            currentAssign.id,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Assignment deactivated.'),
                                backgroundColor: ErpColors.bg,
                              ),
                            );
                          }
                          _loadInitialData();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Student Pickups & Drops',
                        style: GoogleFonts.outfit(color: Colors.redAccent),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(color: ErpColors.textMuted),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ErpColors.bg,
                    ),
                    onPressed:
                        canSave
                            ? () async {
                              final payload = {
                                'studentId': student.id,
                                'busId': selBus!.id,
                                'routeId': route!.id,
                                'pickupStopId': selPickup!.id,
                                'dropStopId': selDrop!.id,
                                'academicYearId': selYear!['id'],
                                'startDate': _today(),
                              };
                              Navigator.pop(context);
                              try {
                                await _busService.assignStudent(payload);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Student assigned successfully!',
                                      ),
                                      backgroundColor: ErpColors.bg,
                                    ),
                                  );
                                }
                                _loadInitialData();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            }
                            : null,
                    child: Text(
                      'Save Assignment',
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final assignedCount =
        _activeAssignments
            .where((a) => a.status.toUpperCase() == 'ACTIVE')
            .length;

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.bgWhite,
        title: Text(
          'Student Assignments',
          style: GoogleFonts.outfit(
            color: ErpColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.clear_all, color: ErpColors.primary),
              label: Text(
                'Clear',
                style: GoogleFonts.outfit(
                  color: ErpColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const _AssignmentsSkeleton()
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ══════════════════════════════════════════════
                  //   FILTER PANEL — always visible
                  // ══════════════════════════════════════════════
                  Container(
                    color: ErpColors.bgWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Row 1: search
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by name or roll number…',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: ErpColors.bgWhite,
                          ),
                          onChanged: (v) {
                            setState(() => _searchQuery = v);
                            _applyFilters();
                          },
                        ),
                        SizedBox(height: 10),

                        // Row 2: Dept | Year
                        Row(
                          children: [
                            // Department
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedDept,
                                decoration: InputDecoration(
                                  labelText: 'Department',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: ErpColors.bgWhite,
                                ),
                                dropdownColor: ErpColors.bgWhite,
                                hint: Text(
                                  'Select...',
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Departments'),
                                  ),
                                  ..._depts.map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _selectedDept = v);
                                  _applyFilters();
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            // Year
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedYear,
                                decoration: InputDecoration(
                                  labelText: 'Year',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: ErpColors.bgWhite,
                                ),
                                dropdownColor: ErpColors.bgWhite,
                                hint: Text(
                                  'Select...',
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Years'),
                                  ),
                                  ..._years.map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('Year $y'),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _selectedYear = v);
                                  _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // Row 3: Residency | Transport status
                        Row(
                          children: [
                            // Residency
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedResidency,
                                decoration: InputDecoration(
                                  labelText: 'Residency',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: ErpColors.bgWhite,
                                ),
                                dropdownColor: ErpColors.bgWhite,
                                hint: Text(
                                  'Select...',
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Types'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'DAY_SCHOLAR',
                                    child: Text('Day Scholar'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'HOSTELLER',
                                    child: Text('Hosteller'),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _selectedResidency = v);
                                  _applyFilters();
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            // Transport status
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedTransportStatus,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: ErpColors.bgWhite,
                                ),
                                dropdownColor: ErpColors.bgWhite,
                                hint: Text(
                                  'Select...',
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Status'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'ASSIGNED',
                                    child: Text('Assigned'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'UNASSIGNED',
                                    child: Text('Unassigned'),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _selectedTransportStatus = v);
                                  _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Summary bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      'Showing ${_filteredStudents.length} of ${_allStudents.length} students'
                      '  ·  Assigned: $assignedCount',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: ErpColors.textMuted,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // ── Student list ──
                  Expanded(
                    child:
                        _filteredStudents.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 52,
                                    color: ErpColors.textMuted,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Select Option',
                                    style: GoogleFonts.outfit(
                                      color: ErpColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_hasFilters) ...[
                                    SizedBox(height: 10),
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: Text('Clear all filters'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final s = _filteredStudents[index];
                                final assignment = _assignmentFor(s.id);
                                final isHosteller = s.residencyType
                                    .toUpperCase()
                                    .contains('HOSTEL');

                                final initials =
                                    s.name.trim().isNotEmpty
                                        ? (s.name.trim().contains(' ')
                                                ? '${s.name.trim().split(' ')[0][0]}${s.name.trim().split(' ')[1][0]}'
                                                : s.name.trim().substring(
                                                  0,
                                                  s.name.length >= 2 ? 2 : 1,
                                                ))
                                            .toUpperCase()
                                        : '?';
                                final isAssigned = assignment != null;

                                return Container(
                                  key: ValueKey(s.id),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: ErpColors.bgWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black12,
                                      width: 1,
                                    ),
                                    boxShadow: [],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: ErpColors.primary,
                                                shape: BoxShape.circle,
                                                boxShadow: [],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  initials,
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 14),
                                            // Main Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    s.name,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color:
                                                          ErpColors.textPrimary,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '${s.rollNumber}  �  ${s.department} (Yr ${s.year})',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      color:
                                                          ErpColors.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Action Button
                                            InkWell(
                                              onTap: () => _showAssignDialog(s),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isAssigned
                                                          ? Colors.transparent
                                                          : ErpColors.primary,
                                                  border:
                                                      isAssigned
                                                          ? Border.all(
                                                            color: ErpColors
                                                                .primary
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                          )
                                                          : null,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow:
                                                      isAssigned
                                                          ? []
                                                          : [
                                                            BoxShadow(
                                                              color: ErpColors
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 4,
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ],
                                                ),
                                                child: Text(
                                                  isAssigned
                                                      ? 'Edit'
                                                      : 'Assign',
                                                  style: GoogleFonts.outfit(
                                                    color:
                                                        isAssigned
                                                            ? ErpColors.primary
                                                            : Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isHosteller || isAssigned) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 14,
                                              bottom: 12,
                                            ),
                                            child: const Divider(
                                              color: Colors.black26,
                                              height: 1,
                                            ),
                                          ),
                                          // Status badges
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (isHosteller)
                                                _badge(
                                                  'Hosteller',
                                                  Colors.amber.shade900,
                                                  Colors.amber.shade100,
                                                  Icons.home_work_rounded,
                                                )
                                              else if (!isAssigned)
                                                _badge(
                                                  'Unassigned',
                                                  Colors.grey.shade800,
                                                  Colors.grey.shade200,
                                                  Icons.directions_walk_rounded,
                                                ),

                                              if (isAssigned) ...[
                                                _badge(
                                                  'Bus ${assignment!.bus.busNumber}',
                                                  Colors.blue.shade800,
                                                  Colors.blue.shade50,
                                                  Icons.directions_bus_rounded,
                                                ),
                                                if (assignment!.pickupStop !=
                                                    null)
                                                  _badge(
                                                    '${assignment!.pickupStop!.stopName}',
                                                    Colors.green.shade800,
                                                    Colors.green.shade50,
                                                    Icons.arrow_upward_rounded,
                                                  ),
                                                if (assignment!.dropStop !=
                                                    null)
                                                  _badge(
                                                    '${assignment!.dropStop!.stopName}',
                                                    Colors.deepOrange.shade800,
                                                    Colors.deepOrange.shade50,
                                                    Icons
                                                        .arrow_downward_rounded,
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _badge(String label, Color fg, Color bg, [IconData? icon]) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
