import 'dart:io';

void main() {
  final file = File('lib/screens/admin/student_management.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll('const Color(0xFF1E1E35)', 'ErpColors.bgWhite');
  content = content.replaceAll('const Color(0xFF1A1A2E)', 'ErpColors.bgWhite');
  content = content.replaceAll('Colors.white54', 'ErpColors.textMuted');
  content = content.replaceAll('Colors.white70', 'ErpColors.textSecondary');
  content = content.replaceAll(
    'Colors.white.withOpacity(0.05)',
    'ErpColors.border',
  );
  content = content.replaceAll('const Color(0xFF6C63FF)', 'ErpColors.primary');
  content = content.replaceAll('Colors.white10', 'ErpColors.border');
  content = content.replaceAll('Colors.white', 'ErpColors.textPrimary');

  file.writeAsStringSync(content);
  print('Done converting UI colors');
}
