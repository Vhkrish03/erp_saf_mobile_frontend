import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system.dart';
import 'dashboard_screen.dart';
import 'timetable_screen.dart';
import 'notices_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final String studentId;
  const MainShell({super.key, required this.studentId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(studentId: widget.studentId),
      const TimetableScreen(embedded: true),
      NoticesScreen(embedded: true, studentId: widget.studentId),
      EventsScreen(embedded: true, studentId: widget.studentId),
      ProfileScreen(embedded: true, studentId: widget.studentId),
    ];
  }

  void _onNavTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) _DesktopNavigation(index: _index, onChanged: _onNavTap),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : Container(
        decoration: BoxDecoration(
          color: ErpColors.bgWhite,
          border: Border(top: BorderSide(color: ErpColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  selected: _index == 0,
                  onTap: () => _onNavTap(0),
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Timetable',
                  selected: _index == 1,
                  onTap: () => _onNavTap(1),
                ),
                _NavItem(
                  icon: Icons.campaign_outlined,
                  label: 'Notices',
                  selected: _index == 2,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  icon: Icons.celebration_outlined,
                  label: 'Events',
                  selected: _index == 3,
                  onTap: () => _onNavTap(3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  selected: _index == 4,
                  onTap: () => _onNavTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _DesktopNavigation({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_rounded, 'Overview'),
      (Icons.calendar_month_outlined, 'Timetable'),
      (Icons.campaign_outlined, 'Notices'),
      (Icons.event_outlined, 'Events'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      width: 244,
      color: ErpColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 34),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ErpColors.accent,
                    borderRadius: ErpRadius.cardSm,
                  ),
                  child: const Icon(Icons.school_rounded, color: ErpColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'College ERP',
                  style: ErpTypography.titleLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Text(
            'STUDENT PORTAL',
            style: ErpTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.52),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...items.indexed.map(
            (entry) => _DesktopNavItem(
              icon: entry.$2.$1,
              label: entry.$2.$2,
              selected: index == entry.$1,
              onTap: () => onChanged(entry.$1),
            ),
          ),
          const Spacer(),
          Text(
            'Academic resource planning',
            style: ErpTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: ErpRadius.cardSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: ErpRadius.cardSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? ErpColors.accent : Colors.white70),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: ErpTypography.bodyMedium.copyWith(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? ErpColors.primarySurface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? ErpColors.primary : ErpColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? ErpColors.primary : ErpColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
