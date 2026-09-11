import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// COLLEGE ERP — GLOBAL DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════

// ── Color Tokens ─────────────────────────────────────────────
class ErpColors {
  ErpColors._();

  // Primary Brand — Deep Academic Navy
  static const Color primary = Color(0xFF16223F);
  static const Color primaryLight = Color(0xFF243354);
  static const Color primarySurface = Color(0xFFEEF1F8);

  // Accent — Warm Brass / Institutional Gold
  static const Color accent = Color(0xFFC9982F);
  static const Color accentLight = Color(0xFFF5E6BE);

  // Backgrounds
  static const Color bg = Color(0xFFF5F6FA);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFF8F9FC);

  // Text
  static const Color textPrimary = Color(0xFF0F1929);
  static const Color textSecondary = Color(0xFF5A6475);
  static const Color textMuted = Color(0xFF8D97A8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Surface & Borders
  static const Color border = Color(0xFFE8EAF0);
  static const Color borderFocus = Color(0xFF16223F);
  static const Color divider = Color(0xFFEAECF0);

  // Status Colors
  static const Color success = Color(0xFF1A8A4A);
  static const Color successSurface = Color(0xFFE6F5EC);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSurface = Color(0xFFFEF3E2);
  static const Color danger = Color(0xFFB01B1B);
  static const Color dangerSurface = Color(0xFFFCEBEB);
  static const Color info = Color(0xFF1D6FA4);
  static const Color infoSurface = Color(0xFFE8F3FB);

  // Module Colors (academic, restrained palette)
  static const Color attendance = Color(0xFF1B6B5A);
  static const Color attendanceSurface = Color(0xFFE6F2EF);
  static const Color results = Color(0xFF5E3B8C);
  static const Color resultsSurface = Color(0xFFEFEAF7);
  static const Color fees = Color(0xFFB45309);
  static const Color feesSurface = Color(0xFFFEF3E2);
  static const Color timetable = Color(0xFF1D6FA4);
  static const Color timetableSurface = Color(0xFFE8F3FB);
  static const Color library = Color(0xFF7A3D3D);
  static const Color librarySurface = Color(0xFFF5EAEA);
  static const Color transport = Color(0xFF1B4A8A);
  static const Color transportSurface = Color(0xFFE6EEFA);
  static const Color assessment = Color(0xFF2D6A4F);
  static const Color assessmentSurface = Color(0xFFE8F4EF);
}

// ── Typography Tokens ─────────────────────────────────────────
class ErpTypography {
  ErpTypography._();

  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: ErpColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: ErpColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ErpColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: ErpColors.textPrimary,
    height: 1.35,
  );

  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: ErpColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ErpColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ErpColors.textPrimary,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ErpColors.textSecondary,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: ErpColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: ErpColors.textSecondary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ErpColors.textMuted,
  );

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: ErpColors.textMuted,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: ErpColors.textMuted,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ErpColors.textMuted,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle statNumber = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ErpColors.textPrimary,
  );

  static TextStyle statNumberSmall = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ErpColors.textPrimary,
  );

  static TextStyle mono = GoogleFonts.sourceCodePro(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: ErpColors.textPrimary,
  );
}

// ── Spacing Tokens ────────────────────────────────────────────
class ErpSpacing {
  ErpSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 16,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(20);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: 24);
}

// ── Radius Tokens ─────────────────────────────────────────────
class ErpRadius {
  ErpRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 100;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get cardSm => BorderRadius.circular(md);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get badge => BorderRadius.circular(full);
  static BorderRadius get input => BorderRadius.circular(md);
  static BorderRadius get dialog => BorderRadius.circular(xl);
}

// ── Elevation / Shadow Tokens ─────────────────────────────────
class ErpShadow {
  ErpShadow._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF16223F).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardHover => [
    BoxShadow(
      color: const Color(0xFF16223F).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(
      color: const Color(0xFF16223F).withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get dialog => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}

// ── Duration Tokens ───────────────────────────────────────────
class ErpDuration {
  ErpDuration._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration skeleton = Duration(milliseconds: 1000);
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE COMPONENT LIBRARY
// ═══════════════════════════════════════════════════════════════

// ── ErpCard ───────────────────────────────────────────────────
class ErpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;
  final Border? border;

  const ErpCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
    this.shadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? ErpSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? ErpColors.bgCard,
        borderRadius: borderRadius ?? ErpRadius.card,
        border: border ?? Border.all(color: ErpColors.border),
        boxShadow: shadow ?? ErpShadow.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? ErpRadius.card,
          child: card,
        ),
      );
    }
    return card;
  }
}

// ── ErpSectionHeader ──────────────────────────────────────────
class ErpSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Widget? badge;

  const ErpSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onAction,
    this.actionLabel,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ErpSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ErpTypography.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: ErpTypography.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (badge != null)
            badge!
          else if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: ErpColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: ErpSpacing.sm,
                  vertical: 4,
                ),
              ),
              child: Text(
                actionLabel!,
                style: ErpTypography.labelLarge.copyWith(
                  color: ErpColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── ErpStatCard ───────────────────────────────────────────────
class ErpStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? surfaceColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? badge;

  const ErpStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.surfaceColor,
    this.subtitle,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ErpCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceColor ?? color.withValues(alpha: 0.10),
                  borderRadius: ErpRadius.cardSm,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (badge != null) ...[const Spacer(), badge!],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: ErpTypography.statNumberSmall.copyWith(
              color: ErpColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: ErpTypography.bodySmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: ErpTypography.caption),
          ],
        ],
      ),
    );
  }
}

// ── ErpStatusBadge ────────────────────────────────────────────
class ErpStatusBadge extends StatelessWidget {
  final String label;
  final ErpBadgeType type;
  final bool compact;

  const ErpStatusBadge({
    super.key,
    required this.label,
    this.type = ErpBadgeType.neutral,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (type) {
      ErpBadgeType.success => (ErpColors.success, ErpColors.successSurface),
      ErpBadgeType.warning => (ErpColors.warning, ErpColors.warningSurface),
      ErpBadgeType.danger => (ErpColors.danger, ErpColors.dangerSurface),
      ErpBadgeType.info => (ErpColors.info, ErpColors.infoSurface),
      ErpBadgeType.primary => (ErpColors.primary, ErpColors.primarySurface),
      ErpBadgeType.accent => (ErpColors.accent, ErpColors.accentLight),
      ErpBadgeType.neutral => (ErpColors.textSecondary, ErpColors.bgSubtle),
    };

    return Container(
      padding:
          compact
              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ErpRadius.badge,
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: ErpTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum ErpBadgeType { success, warning, danger, info, primary, accent, neutral }

// ── ErpButton ─────────────────────────────────────────────────
class ErpButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ErpButtonType type;
  final bool loading;
  final bool fullWidth;
  final EdgeInsets? padding;

  const ErpButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.type = ErpButtonType.primary,
    this.loading = false,
    this.fullWidth = false,
    this.padding,
  });

  factory ErpButton.secondary({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool fullWidth = false,
  }) => ErpButton(
    label: label,
    icon: icon,
    onPressed: onPressed,
    type: ErpButtonType.secondary,
    fullWidth: fullWidth,
  );

  factory ErpButton.destructive({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool fullWidth = false,
  }) => ErpButton(
    label: label,
    icon: icon,
    onPressed: onPressed,
    type: ErpButtonType.destructive,
    fullWidth: fullWidth,
  );

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (type) {
      ErpButtonType.primary => (
        ErpColors.primary,
        Colors.white,
        Colors.transparent,
      ),
      ErpButtonType.secondary => (
        ErpColors.bgWhite,
        ErpColors.primary,
        ErpColors.border,
      ),
      ErpButtonType.destructive => (
        ErpColors.danger,
        Colors.white,
        Colors.transparent,
      ),
      ErpButtonType.ghost => (
        Colors.transparent,
        ErpColors.primary,
        Colors.transparent,
      ),
    };

    Widget content =
        loading
            ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: fg),
                  const SizedBox(width: 7),
                ],
                Text(label, style: ErpTypography.button.copyWith(color: fg)),
              ],
            );

    final button = AnimatedContainer(
      duration: ErpDuration.fast,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ErpRadius.button,
        border: Border.all(color: border),
        boxShadow:
            type == ErpButtonType.primary
                ? [
                  BoxShadow(
                    color: ErpColors.primary.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                : null,
      ),
      child: Center(child: content),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: ErpRadius.button,
          child: button,
        ),
      ),
    );
  }
}

enum ErpButtonType { primary, secondary, destructive, ghost }

// ── ErpTextField ──────────────────────────────────────────────
class ErpTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;

  const ErpTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: ErpTypography.titleSmall),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          focusNode: focusNode,
          style: ErpTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ErpTypography.bodyMedium.copyWith(
              color: ErpColors.textMuted,
            ),
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, size: 18, color: ErpColors.textMuted)
                    : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? ErpColors.bgWhite : ErpColors.bgSubtle,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: ErpRadius.input,
              borderSide: const BorderSide(color: ErpColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: ErpRadius.input,
              borderSide: const BorderSide(color: ErpColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: ErpRadius.input,
              borderSide: const BorderSide(
                color: ErpColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: ErpRadius.input,
              borderSide: const BorderSide(color: ErpColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

// ── ErpEmptyState ─────────────────────────────────────────────
class ErpEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErpEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ErpSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ErpColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: ErpColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: ErpSpacing.base),
            Text(
              message,
              style: ErpTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: ErpTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: ErpSpacing.lg),
              ErpButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

// ── ErpErrorState ─────────────────────────────────────────────
class ErpErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErpErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ErpSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: ErpColors.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 32,
                color: ErpColors.danger,
              ),
            ),
            const SizedBox(height: ErpSpacing.base),
            Text('Something went wrong', style: ErpTypography.headlineSmall),
            const SizedBox(height: 6),
            Text(
              message,
              style: ErpTypography.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: ErpSpacing.lg),
              ErpButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── ErpSkeleton ───────────────────────────────────────────────
class ErpSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const ErpSkeleton({super.key, this.width, this.height = 16, this.radius = 6});

  @override
  State<ErpSkeleton> createState() => _ErpSkeletonState();
}

class _ErpSkeletonState extends State<ErpSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder:
          (_, __) => Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: ErpColors.border.withValues(alpha: _animation.value * 1.5),
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
    );
  }
}

class ErpSkeletonCard extends StatelessWidget {
  const ErpSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ErpSkeleton(width: 36, height: 36, radius: 8),
          const SizedBox(height: 12),
          const ErpSkeleton(width: 80, height: 22, radius: 4),
          const SizedBox(height: 6),
          const ErpSkeleton(height: 13),
        ],
      ),
    );
  }
}

class ErpSkeletonListItem extends StatelessWidget {
  const ErpSkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ErpCard(
        child: Row(
          children: [
            const ErpSkeleton(width: 44, height: 44, radius: 10),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ErpSkeleton(height: 14),
                  const SizedBox(height: 7),
                  ErpSkeleton(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ErpAppBar ─────────────────────────────────────────────────
class ErpAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final Color? backgroundColor;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  const ErpAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.backgroundColor,
    this.onBack,
    this.bottom,
  });

  @override
  Size get preferredSize {
    double height = subtitle != null ? 68.0 : kToolbarHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: subtitle != null ? 68.0 : kToolbarHeight,
      backgroundColor: backgroundColor ?? ErpColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: showBack,
      leading:
          showBack
              ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              )
              : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

// ── ErpPageHeader ─────────────────────────────────────────────
class ErpPageHeader extends StatelessWidget {
  final String name;
  final String? role;
  final String? subtitle;
  final String? employeeId;
  final Widget? trailing;
  final Color backgroundColor;
  final bool showNotification;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const ErpPageHeader({
    super.key,
    required this.name,
    this.role,
    this.subtitle,
    this.employeeId,
    this.trailing,
    this.backgroundColor = ErpColors.primary,
    this.showNotification = true,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(ErpRadius.xl),
          bottomRight: Radius.circular(ErpRadius.xl),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ErpRadius.md),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role != null)
                  Text(
                    role!,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showNotification)
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
              onPressed: onNotificationTap,
            ),
        ],
      ),
    );
  }
}

// ── ErpInfoRow ────────────────────────────────────────────────
class ErpInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const ErpInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? ErpColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: ErpTypography.bodySmall),
          ),
          Expanded(child: Text(value, style: ErpTypography.titleSmall)),
        ],
      ),
    );
  }
}

// ── ErpDivider ────────────────────────────────────────────────
class ErpDivider extends StatelessWidget {
  final double indent;
  const ErpDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: ErpColors.divider,
      thickness: 1,
      indent: indent,
      endIndent: indent,
      height: 1,
    );
  }
}

// ── ErpConfirmDialog ──────────────────────────────────────────
class ErpConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ErpConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.isDestructive = false,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => ErpConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            isDestructive: isDestructive,
            onConfirm: onConfirm,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
      backgroundColor: ErpColors.bgWhite,
      child: Padding(
        padding: const EdgeInsets.all(ErpSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isDestructive
                            ? ErpColors.dangerSurface
                            : ErpColors.primarySurface,
                    borderRadius: BorderRadius.circular(ErpRadius.sm),
                  ),
                  child: Icon(
                    isDestructive ? Icons.delete_outline : Icons.help_outline,
                    color: isDestructive ? ErpColors.danger : ErpColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: ErpTypography.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: ErpSpacing.base),
            Text(message, style: ErpTypography.bodyMedium),
            const SizedBox(height: ErpSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: ErpButton.secondary(
                    label: 'Cancel',
                    fullWidth: true,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      isDestructive
                          ? ErpButton.destructive(
                            label: confirmLabel,
                            fullWidth: true,
                            onPressed: () {
                              Navigator.pop(context, true);
                              onConfirm();
                            },
                          )
                          : ErpButton(
                            label: confirmLabel,
                            fullWidth: true,
                            onPressed: () {
                              Navigator.pop(context, true);
                              onConfirm();
                            },
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── ErpSnackbar ───────────────────────────────────────────────
class ErpSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    ErpBadgeType type = ErpBadgeType.neutral,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (bg, icon) = switch (type) {
      ErpBadgeType.success => (ErpColors.success, Icons.check_circle_outline),
      ErpBadgeType.warning => (ErpColors.warning, Icons.warning_amber_outlined),
      ErpBadgeType.danger => (ErpColors.danger, Icons.error_outline),
      ErpBadgeType.info => (ErpColors.info, Icons.info_outline),
      _ => (ErpColors.textPrimary, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ErpRadius.md),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// ── ErpSearchBar ──────────────────────────────────────────────
class ErpSearchBar extends StatelessWidget {
  final String hint;
  final void Function(String) onChanged;
  final TextEditingController? controller;

  const ErpSearchBar({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: ErpTypography.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ErpTypography.bodyMedium.copyWith(
          color: ErpColors.textMuted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: ErpColors.textMuted,
        ),
        filled: true,
        fillColor: ErpColors.bgWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: ErpRadius.input,
          borderSide: const BorderSide(color: ErpColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ErpRadius.input,
          borderSide: const BorderSide(color: ErpColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ErpRadius.input,
          borderSide: const BorderSide(color: ErpColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

// ── Module Card for Dashboards ────────────────────────────────
class ErpModuleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color surfaceColor;
  final VoidCallback? onTap;
  final String? badge;

  const ErpModuleCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.surfaceColor,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ErpColors.bgWhite,
      borderRadius: ErpRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: ErpRadius.card,
        child: Container(
          decoration: BoxDecoration(
            color: ErpColors.bgWhite,
            borderRadius: ErpRadius.card,
            border: Border.all(color: ErpColors.border),
            boxShadow: ErpShadow.card,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(ErpRadius.md),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ErpTypography.labelMedium.copyWith(
                      color: ErpColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ErpColors.danger,
                      borderRadius: ErpRadius.badge,
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Global ThemeData ──────────────────────────────────────────
ThemeData get erpTheme {
  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: ErpColors.bg,
    primaryColor: ErpColors.primary,
    colorScheme: ColorScheme.light(
      primary: ErpColors.primary,
      secondary: ErpColors.accent,
      surface: ErpColors.bgWhite,
      error: ErpColors.danger,
    ),
    textTheme: TextTheme(
      displayLarge: ErpTypography.displayLarge,
      displayMedium: ErpTypography.displayMedium,
      headlineMedium: ErpTypography.headlineLarge,
      headlineSmall: ErpTypography.headlineMedium,
      titleLarge: ErpTypography.titleLarge,
      titleMedium: ErpTypography.titleMedium,
      bodyLarge: ErpTypography.bodyLarge,
      bodyMedium: ErpTypography.bodyMedium,
      labelLarge: ErpTypography.labelLarge,
      labelSmall: ErpTypography.labelSmall,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ErpColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    cardTheme: CardThemeData(
      color: ErpColors.bgWhite,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: ErpRadius.card,
        side: const BorderSide(color: ErpColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: ErpColors.divider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ErpColors.bgWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: ErpRadius.input,
        borderSide: const BorderSide(color: ErpColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: ErpRadius.input,
        borderSide: const BorderSide(color: ErpColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: ErpRadius.input,
        borderSide: const BorderSide(color: ErpColors.primary, width: 1.6),
      ),
      errorMaxLines: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: ErpRadius.button),
        textStyle: ErpTypography.button,
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ErpColors.bgWhite,
      selectedItemColor: ErpColors.primary,
      unselectedItemColor: ErpColors.textMuted,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ErpColors.bgWhite,
      shape: RoundedRectangleBorder(borderRadius: ErpRadius.dialog),
      elevation: 4,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(ErpColors.bgSubtle),
      dataRowMinHeight: 52,
      dataRowMaxHeight: 64,
      headingTextStyle: ErpTypography.labelMedium.copyWith(
        color: ErpColors.textSecondary,
      ),
      dataTextStyle: ErpTypography.bodyMedium.copyWith(
        color: ErpColors.textPrimary,
      ),
      dividerThickness: 1,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: ErpDuration.fast,
      decoration: BoxDecoration(
        color: ErpColors.textPrimary,
        borderRadius: ErpRadius.cardSm,
      ),
      textStyle: ErpTypography.caption.copyWith(color: Colors.white),
    ),
    focusColor: ErpColors.primary.withValues(alpha: 0.12),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ErpRadius.md),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ErpColors.bgSubtle,
      selectedColor: ErpColors.primarySurface,
      labelStyle: ErpTypography.labelMedium,
      side: const BorderSide(color: ErpColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ErpRadius.full),
      ),
    ),
  );
}
