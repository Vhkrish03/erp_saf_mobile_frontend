import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/bus_model.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart';
import '../services/bus_service.dart';

class AdminManageBusesScreen extends StatefulWidget {
  const AdminManageBusesScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageBusesScreen> createState() => _AdminManageBusesScreenState();
}

class _BusesSkeleton extends StatelessWidget {
  const _BusesSkeleton();

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

class _AdminManageBusesScreenState extends State<AdminManageBusesScreen> {
  final BusService _busService = BusService();
  List<BusModel> _buses = [];
  List<DriverModel> _drivers = [];
  List<RouteModel> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllTransportData();
  }

  Future<void> _loadAllTransportData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _busService.getBuses();
      final drivers = await _busService.getDrivers();
      final routes = await _busService.getRoutes();
      setState(() {
        _buses = list;
        _drivers =
            drivers
                .where((d) => d.status.trim().toUpperCase() == 'ACTIVE')
                .toList();
        _routes =
            routes
                .where((r) => r.status.trim().toUpperCase() == 'ACTIVE')
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transport data: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isWarning ? ErpColors.danger : ErpColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isWarning ? ErpColors.danger : ErpColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ErpTypography.caption.copyWith(
                  color: ErpColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: ErpTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWarning ? ErpColors.danger : ErpColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBusDialog({BusModel? bus}) {
    final busNumController = TextEditingController(text: bus?.busNumber ?? '');
    final regNumController = TextEditingController(
      text: bus?.registrationNumber ?? '',
    );
    final capacityController = TextEditingController(
      text: bus?.capacity.toString() ?? '50',
    );
    final busInchargeController = TextEditingController(
      text: bus?.busInchargeName ?? '',
    );
    String busType = bus?.busType ?? 'STANDARD';
    String status = bus?.status ?? 'ACTIVE';

    int? selectedDriverId = bus?.driver?.id;
    int? selectedRouteId = bus?.route?.id;

    // Check if the assigned driver/route are still in active listings, if not add them
    if (bus?.driver != null && !_drivers.any((d) => d.id == bus!.driver!.id)) {
      _drivers.add(bus!.driver!);
    }
    if (bus?.route != null && !_routes.any((r) => r.id == bus!.route!.id)) {
      _routes.add(bus!.route!);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ErpColors.bgWhite,
              surfaceTintColor: ErpColors.bgWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                bus == null ? 'Add Bus' : 'Edit Bus',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ErpColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: busNumController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Bus Number (e.g. BUS-05)',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.directions_bus_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: regNumController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Registration Number',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.tag_rounded,
                            color: ErpColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: capacityController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Seating Capacity',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.airline_seat_recline_normal,
                            color: ErpColors.primary,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: busInchargeController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Bus Incharge Name',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: ErpColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: busType,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Bus Type',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                        dropdownColor: ErpColors.bgWhite,
                        items: const [
                          DropdownMenuItem(
                            value: 'STANDARD',
                            child: Text('STANDARD'),
                          ),
                          DropdownMenuItem(
                            value: 'DELUXE',
                            child: Text('DELUXE'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => busType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: selectedDriverId,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Assign Driver',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                        dropdownColor: ErpColors.bgWhite,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Driver Assigned'),
                          ),
                          ..._drivers.map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setDialogState(() => selectedDriverId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: selectedRouteId,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Assign Route',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.route_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                        dropdownColor: ErpColors.bgWhite,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Route Assigned'),
                          ),
                          ..._routes.map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.routeName),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setDialogState(() => selectedRouteId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: status,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.toggle_on_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                        dropdownColor: ErpColors.bgWhite,
                        items: const [
                          DropdownMenuItem(
                            value: 'ACTIVE',
                            child: Text('ACTIVE'),
                          ),
                          DropdownMenuItem(
                            value: 'INACTIVE',
                            child: Text('INACTIVE'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: ErpColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ErpColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final busNum = busNumController.text.trim();
                    final regNum = regNumController.text.trim();
                    if (busNum.isEmpty || regNum.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bus Number and Registration Number are required.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final body = {
                      'busNumber': busNum,
                      'registrationNumber': regNum,
                      'busType': busType,
                      'capacity': int.tryParse(capacityController.text) ?? 50,
                      'busInchargeName': busInchargeController.text.trim(),
                      'status': status,
                      'driverId': selectedDriverId,
                      'routeId': selectedRouteId,
                    };

                    try {
                      if (bus == null) {
                        await _busService.createBus(body);
                      } else {
                        await _busService.updateBus(bus.id, body);
                      }
                      Navigator.pop(context);
                      _loadAllTransportData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: ErpColors.primary,
        title: Text(
          'Manage Buses',
          style: GoogleFonts.outfit(
            color: ErpColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.directions_bus, color: ErpColors.textOnPrimary),
            onPressed: () => _showBusDialog(),
            tooltip: 'Add Bus',
          ),
        ],
      ),
      body:
          _isLoading
              ? const _BusesSkeleton()
              : _buses.isEmpty
              ? Center(
                child: Text(
                  'No buses defined yet.',
                  style: ErpTypography.bodyMedium,
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _buses.length,
                itemBuilder: (context, index) {
                  final b = _buses[index];
                  final isActive = b.status == 'ACTIVE';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ErpCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ErpColors.primary,
                                      ErpColors.primary.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    ErpRadius.md,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ErpColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_bus_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.busNumber,
                                      style: ErpTypography.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'College Transport Bus',
                                      style: ErpTypography.bodySmall.copyWith(
                                        color: ErpColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ErpStatusBadge(
                                label: b.status,
                                type:
                                    isActive
                                        ? ErpBadgeType.success
                                        : ErpBadgeType.danger,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: ErpColors.bg,
                              borderRadius: BorderRadius.circular(ErpRadius.md),
                              border: Border.all(color: ErpColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.tag_rounded,
                                        'Registration',
                                        b.registrationNumber.isEmpty
                                            ? 'N/A'
                                            : b.registrationNumber,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.airline_seat_recline_normal,
                                        'Capacity',
                                        '${b.capacity} Seats',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.category_outlined,
                                        'Bus Type',
                                        b.busType,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.person_outline,
                                        'Bus Incharge',
                                        b.busInchargeName.isEmpty
                                            ? 'Unassigned'
                                            : b.busInchargeName,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.badge_outlined,
                                        'Driver',
                                        b.driver?.name ?? "Unassigned",
                                        isWarning: b.driver == null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.route_outlined,
                                        'Route',
                                        b.route?.routeName ?? "Unassigned",
                                        isWarning: b.route == null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: ErpColors.border),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ErpColors.primary
                                        .withValues(alpha: 0.1),
                                    foregroundColor: ErpColors.primary,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () => _showBusDialog(bus: b),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ErpColors.danger
                                        .withValues(alpha: 0.1),
                                    foregroundColor: ErpColors.danger,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            backgroundColor: ErpColors.bgWhite,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: ErpRadius.dialog,
                                            ),
                                            title: Text(
                                              'Confirm Delete',
                                              style:
                                                  ErpTypography.headlineSmall,
                                            ),
                                            content: Text(
                                              'Are you sure you want to remove ${b.busNumber}?',
                                              style: ErpTypography.bodyMedium,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  'Cancel',
                                                  style:
                                                      ErpTypography.bodyMedium,
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      ErpColors.danger,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await _busService.deleteBus(b.id);
                                        _loadAllTransportData();
                                        ErpSnackbar.show(
                                          context,
                                          message: 'Bus deleted successfully.',
                                          type: ErpBadgeType.success,
                                        );
                                      } catch (e) {
                                        ErpSnackbar.show(
                                          context,
                                          message: 'Error: $e',
                                          type: ErpBadgeType.danger,
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
