import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/teacher.dart';
import '../services/teacher_service.dart';

class ProfileScreen extends StatefulWidget {
  final String employeeId;
  const ProfileScreen({super.key, required this.employeeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TeacherService _service = TeacherService();
  late Future<Teacher> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getTeacherProfile(widget.employeeId);
  }

  Future<void> _openEditSheet(Teacher teacher) async {
    final updated = await showModalBottomSheet<Teacher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(teacher: teacher, service: _service),
    );
    if (updated != null) {
      setState(() => _future = Future.value(updated));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(
        title: 'My Profile',
        subtitle: 'Academic staff record',
      ),
      body: FutureBuilder<Teacher>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _TeacherProfileSkeleton();
          }
          if (snap.hasError || !snap.hasData) {
            return ErpErrorState(
              message: snap.error?.toString() ?? 'Failed to load profile',
              onRetry:
                  () => setState(
                    () =>
                        _future = _service.getTeacherProfile(widget.employeeId),
                  ),
            );
          }
          final t = snap.data!;
          final initials =
              t.name
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // ── Avatar + Name Banner ─────────────────────────────
                ErpCard(
                  color: ErpColors.primary,
                  shadow: [],
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      t.photoUrl.isNotEmpty
                          ? CircleAvatar(
                            radius: 46,
                            backgroundImage: NetworkImage(t.photoUrl),
                          )
                          : Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: ErpTypography.displayMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      const SizedBox(height: 14),
                      Text(
                        t.name,
                        style: ErpTypography.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.designation,
                        style: ErpTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.department,
                        style: ErpTypography.caption.copyWith(
                          color: ErpColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Details Card ─────────────────────────────────────
                const ErpSectionHeader(title: 'Professional Details'),
                ErpCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _PRow(
                        icon: Icons.badge_outlined,
                        label: 'Employee ID',
                        value: t.employeeId,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.apartment_outlined,
                        label: 'Department',
                        value: t.department,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Designation',
                        value: t.designation,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.timelapse_outlined,
                        label: 'Experience',
                        value: t.experience,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.school_outlined,
                        label: 'Qualification',
                        value: t.qualification,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: t.phone,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: t.email,
                      ),
                      const Divider(height: 18),
                      _PRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: t.address,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Edit Button ──────────────────────────────────────
                ErpButton(
                  label: 'Edit Contact Details',
                  icon: Icons.edit_outlined,
                  fullWidth: true,
                  onPressed: () => _openEditSheet(t),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherProfileSkeleton extends StatelessWidget {
  const _TeacherProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeleton(height: 210, radius: 16),
        SizedBox(height: 16),
        ErpSkeleton(height: 170, radius: 16),
        SizedBox(height: 16),
        ErpSkeleton(height: 170, radius: 16),
      ],
    );
  }
}

class _PRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _PRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: ErpColors.primarySurface,
          borderRadius: BorderRadius.circular(ErpRadius.sm),
        ),
        child: Icon(icon, size: 16, color: ErpColors.primary),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ErpTypography.caption),
            const SizedBox(height: 3),
            Text(value.isEmpty ? '—' : value, style: ErpTypography.bodyLarge),
          ],
        ),
      ),
    ],
  );
}

// ── Edit Profile Bottom Sheet ──────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final Teacher teacher;
  final TeacherService service;
  const _EditProfileSheet({required this.teacher, required this.service});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _phone = TextEditingController(text: widget.teacher.phone);
  late final _email = TextEditingController(text: widget.teacher.email);
  late final _address = TextEditingController(text: widget.teacher.address);
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.teacher.copyWith(
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
    final result = await widget.service.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: ErpColors.bgWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ErpRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ErpColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Contact Details', style: ErpTypography.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              style: ErpTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: ErpColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              style: ErpTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: ErpColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              style: ErpTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: ErpColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ErpButton(
              label: _saving ? 'Saving…' : 'Save Changes',
              icon: Icons.check_rounded,
              fullWidth: true,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
