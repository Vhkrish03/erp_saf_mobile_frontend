import 'dart:io';

void main() {
  final file = File('lib/screens/admin/student_management.dart');
  String content = file.readAsStringSync();

  // Fix bad conversion artifacts
  content = content.replaceAll(
    'ErpColors.textPrimary30',
    'ErpColors.textPrimary.withOpacity(0.3)',
  );
  content = content.replaceAll(
    'ErpColors.textPrimary12',
    'ErpColors.textPrimary.withOpacity(0.12)',
  );
  content = content.replaceAll('ErpColors.textPrimary10', 'ErpColors.border');
  content = content.replaceAll(
    'ErpColors.textPrimary24',
    'ErpColors.textPrimary.withOpacity(0.24)',
  );
  content = content.replaceAll(
    'ErpColors.textPrimary54',
    'ErpColors.textMuted',
  );
  content = content.replaceAll(
    'ErpColors.textPrimary70',
    'ErpColors.textSecondary',
  );

  file.writeAsStringSync(content);
  print('Fixed textPrimary attributes');
}
