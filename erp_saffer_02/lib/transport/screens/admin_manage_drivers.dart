import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system.dart';
import '../models/driver_model.dart';
import '../services/bus_service.dart';

class AdminManageDriversScreen extends StatefulWidget {
  const AdminManageDriversScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageDriversScreen> createState() =>
      _AdminManageDriversScreenState();
}

class _DriversSkeleton extends StatelessWidget {
  const _DriversSkeleton();

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

class _AdminManageDriversScreenState extends State<AdminManageDriversScreen> {
  final BusService _busService = BusService();
  List<DriverModel> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _busService.getDrivers();
      setState(() {
        _drivers = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading drivers: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ErpColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: ErpColors.primary),
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
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDriverDialog({DriverModel? driver}) {
    final nameController = TextEditingController(text: driver?.name ?? '');
    final empIdController = TextEditingController(
      text: driver?.employeeId ?? '',
    );
    final phoneController = TextEditingController(text: driver?.phone ?? '');
    final licController = TextEditingController(
      text: driver?.licenseNumber ?? '',
    );
    final expiryController = TextEditingController(
      text: driver?.licenseExpiry ?? '',
    );
    String status = driver?.status ?? 'ACTIVE';

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
                driver == null ? 'Add New Driver' : 'Edit Driver Info',
                style: GoogleFonts.outfit(
                  color: ErpColors.textPrimary,
                  fontWeight: FontWeight.bold,
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
                        controller: nameController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Driver Name',
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
                      TextField(
                        controller: empIdController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Employee ID',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.tag_rounded,
                            color: ErpColors.primary,
                          ),
                        ),
                        enabled: driver == null,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: licController,
                        style: GoogleFonts.outfit(color: ErpColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'License Number',
                          labelStyle: GoogleFonts.outfit(
                            color: ErpColors.textPrimary,
                          ),
                          prefixIcon: const Icon(
                            Icons.credit_card_outlined,
                            color: ErpColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final DateTime? pickedVal = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 10),
                            ),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: ErpColors.primary,
                                    onPrimary: ErpColors.textOnPrimary,
                                    onSurface: ErpColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedVal != null) {
                            setDialogState(() {
                              expiryController.text =
                                  '${pickedVal.year}-${pickedVal.month.toString().padLeft(2, '0')}-${pickedVal.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextField(
                            controller: expiryController,
                            style: GoogleFonts.outfit(
                              color: ErpColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'License Expiry (YYYY-MM-DD)',
                              labelStyle: GoogleFonts.outfit(
                                color: ErpColors.textPrimary,
                              ),
                              hintText: 'Select Date',
                              prefixIcon: const Icon(
                                Icons.event_outlined,
                                color: ErpColors.primary,
                              ),
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: ErpColors.textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
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
                          if (val != null) {
                            setDialogState(() => status = val);
                          }
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
                    if (nameController.text.trim().isEmpty ||
                        empIdController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and Employee ID are required.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final newDriver = DriverModel(
                      id: driver?.id ?? 0,
                      employeeId: empIdController.text.trim(),
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      licenseNumber: licController.text.trim(),
                      licenseExpiry:
                          expiryController.text.trim().isEmpty
                              ? '2030-01-01'
                              : expiryController.text.trim(),
                      status: status,
                    );

                    try {
                      if (driver == null) {
                        await _busService.createDriver(newDriver);
                      } else {
                        await _busService.updateDriver(driver.id, newDriver);
                      }
                      Navigator.pop(context);
                      _loadDrivers();
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: Text('Error Saving Driver'),
                              content: Text(e.toString()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                      );
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(color: ErpColors.bgWhite),
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
          'Manage Staff / Drivers',
          style: GoogleFonts.outfit(
            color: ErpColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: ErpColors.textOnPrimary),
            onPressed: () => _showDriverDialog(),
            tooltip: 'Add Driver',
          ),
        ],
      ),
      body:
          _isLoading
              ? const _DriversSkeleton()
              : _drivers.isEmpty
              ? Center(
                child: Text(
                  'No drivers added yet.',
                  style: ErpTypography.bodyMedium,
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _drivers.length,
                itemBuilder: (context, index) {
                  final d = _drivers[index];
                  final isActive = d.status == 'ACTIVE';
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
                                  Icons.badge_rounded,
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
                                      d.name,
                                      style: ErpTypography.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Staff Member Profile',
                                      style: ErpTypography.bodySmall.copyWith(
                                        color: ErpColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ErpStatusBadge(
                                label: d.status,
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
                                        'Employee ID',
                                        d.employeeId,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.phone_outlined,
                                        'Phone',
                                        d.phone,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.credit_card_outlined,
                                        'License No.',
                                        d.licenseNumber,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDetailItem(
                                        Icons.event_outlined,
                                        'Expiry Date',
                                        d.licenseExpiry,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                  onPressed: () => _showDriverDialog(driver: d),
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
                                              'Are you sure you want to remove this driver?',
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
                                        await _busService.deleteDriver(d.id);
                                        _loadDrivers();
                                        ErpSnackbar.show(
                                          context,
                                          message:
                                              'Driver deleted successfully.',
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
