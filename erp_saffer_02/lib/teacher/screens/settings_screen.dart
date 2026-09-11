import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'English';
  final _languages = ['English', 'Tamil', 'Hindi'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: const ErpAppBar(
        title: 'Settings',
        subtitle: 'App preferences & account',
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ── Preferences ───────────────────────────────────────
          const ErpSectionHeader(title: 'Preferences'),
          ErpCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchTile(
                  icon: Icons.notifications_outlined,
                  iconColor: ErpColors.info,
                  iconBg: ErpColors.infoSurface,
                  title: 'Notifications',
                  subtitle: 'Receive alerts and updates',
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
                const Divider(height: 1, indent: 56),
                _NavTile(
                  icon: Icons.language_outlined,
                  iconColor: ErpColors.results,
                  iconBg: ErpColors.resultsSurface,
                  title: 'Language',
                  trailing: _language,
                  onTap: () => _showLanguagePicker(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ───────────────────────────────────────────
          const ErpSectionHeader(title: 'About'),
          ErpCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: ErpColors.attendance,
                  iconBg: ErpColors.attendanceSurface,
                  title: 'Privacy Policy',
                  onTap:
                      () => _showInfoSheet(
                        'Privacy Policy',
                        'Your data is used only for academic purposes within the college ERP system and is not shared with third parties.',
                      ),
                ),
                const Divider(height: 1, indent: 56),
                _NavTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: ErpColors.primary,
                  iconBg: ErpColors.primarySurface,
                  title: 'About College ERP',
                  onTap:
                      () => _showInfoSheet(
                        'About College ERP',
                        'College ERP — Teacher Panel\nVersion 2.0.0\n\nA unified platform for academic management built for modern institutions.',
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout Button ──────────────────────────────────
          ErpCard(
            color: ErpColors.dangerSurface,
            border: Border.all(color: ErpColors.danger.withValues(alpha: 0.2)),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ErpColors.dangerSurface,
                  borderRadius: BorderRadius.circular(ErpRadius.sm),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: ErpColors.danger,
                  size: 18,
                ),
              ),
              title: Text(
                'Logout',
                style: ErpTypography.titleMedium.copyWith(
                  color: ErpColors.danger,
                ),
              ),
              subtitle: Text(
                'Sign out of your account',
                style: ErpTypography.bodySmall,
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: ErpColors.danger,
                size: 20,
              ),
              onTap: () => _confirmLogout(),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'College ERP v2.0.0',
              style: ErpTypography.caption.copyWith(color: ErpColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ErpColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ErpRadius.xxl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    'Select Language',
                    style: ErpTypography.headlineSmall,
                  ),
                ),
                ..._languages.map(
                  (lang) => ListTile(
                    title: Text(lang, style: ErpTypography.bodyLarge),
                    trailing:
                        _language == lang
                            ? Icon(
                              Icons.check_rounded,
                              color: ErpColors.primary,
                              size: 20,
                            )
                            : null,
                    onTap: () {
                      setState(() => _language = lang);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ErpColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ErpRadius.xxl),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ErpTypography.headlineMedium),
              const SizedBox(height: 14),
              Text(content, style: ErpTypography.bodyMedium),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ErpColors.bgWhite,
            shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
            title: Text('Logout', style: ErpTypography.headlineSmall),
            content: Text(
              'Are you sure you want to sign out?',
              style: ErpTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}

// ── Reusable Tile Widgets ──────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(ErpRadius.sm),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    ),
    title: Text(title, style: ErpTypography.titleMedium),
    subtitle: Text(subtitle, style: ErpTypography.bodySmall),
    trailing: Switch(
      value: value,
      activeColor: ErpColors.primary,
      onChanged: onChanged,
    ),
  );
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(ErpRadius.sm),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    ),
    title: Text(title, style: ErpTypography.titleMedium),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailing != null) Text(trailing!, style: ErpTypography.bodySmall),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: ErpColors.textMuted,
          size: 20,
        ),
      ],
    ),
  );
}
