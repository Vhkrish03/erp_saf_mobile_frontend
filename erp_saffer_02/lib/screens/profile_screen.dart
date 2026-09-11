import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import 'editcontactscreen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  final String studentId;
  const ProfileScreen({
    super.key,
    this.embedded = false,
    required this.studentId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StudentService api = StudentService();

  Student? currentStudent;

  @override
  void initState() {
    super.initState();
    loadStudent();
  }

  Future<void> loadStudent() async {
    try {
      currentStudent = await api.getStudent(widget.studentId);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStudent == null) {
      return const Scaffold(
        backgroundColor: ErpColors.bg,
        body: _ProfileSkeleton(),
      );
    }

    final body = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: ErpColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ErpColors.accent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  currentStudent!.name
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join(),
                  style: const TextStyle(
                    color: ErpColors.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                currentStudent!.name,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${currentStudent!.rollNumber} · ${currentStudent!.department}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _InfoCard(
          title: 'Academic details',
          rows: [
            _Row('Department', currentStudent!.department),
            _Row('Year', currentStudent!.year),
            _Row('Semester', currentStudent!.semester),
            _Row('Faculty advisor', currentStudent!.advisor),
            _Row('CGPA', currentStudent!.cgpa.toStringAsFixed(2)),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Contact Details',
          editable: true,
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditContactScreen(student: currentStudent!),
              ),
            ).then((_) => loadStudent());
          },
          rows: [
            _Row('Email', currentStudent!.email),
            _Row('Phone', currentStudent!.phone),
            _Row('Emergency Name', currentStudent!.emergencyContactName),
            _Row('Emergency Phone', currentStudent!.emergencyContactPhone),
            _Row('Address', currentStudent!.address),
          ],
        ),
        const SizedBox(height: 24),
        _ActionTile(
          icon: Icons.edit_outlined,
          label: 'Edit profile',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.lock_outline,
          label: 'Change password',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.notifications_outlined,
          label: 'Notification preferences',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.help_outline,
          label: 'Help & support',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Log out',
          color: ErpColors.danger,
          onTap:
              () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
        ),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: AppBar(
          title: const Text('Profile'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(child: body),
      );
    }
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: body,
    );
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  final bool editable;
  final VoidCallback? onEdit;
  const _InfoCard({
    required this.title,
    required this.rows,
    this.editable = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ErpCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (editable)
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      r.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: Theme.of(context).textTheme.bodyLarge,
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
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: [
        const SizedBox(height: 28),
        const Center(child: ErpSkeleton(width: 88, height: 88, radius: 24)),
        const SizedBox(height: 16),
        const Center(child: ErpSkeleton(width: 150, height: 20)),
        const SizedBox(height: 8),
        const Center(child: ErpSkeleton(width: 210, height: 14)),
        const SizedBox(height: 28),
        ErpSkeletonCard(key: const ValueKey('profile-academic')),
        const SizedBox(height: 16),
        ErpSkeletonCard(key: const ValueKey('profile-contact')),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ErpColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ErpColors.bgWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: c),
        title: Text(
          label,
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing:
            color == null
                ? const Icon(
                  Icons.chevron_right_rounded,
                  color: ErpColors.textMuted,
                )
                : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
