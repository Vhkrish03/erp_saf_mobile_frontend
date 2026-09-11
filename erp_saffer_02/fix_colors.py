import re
import sys

file_path = r'c:/Users/HARIKH/sparkhinfotechprojects/erp-college/erp_saffer_02/lib/teacher/screens/test_entry_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace hardcoded dark background and border colors
content = content.replace('Color(0xFF1E1E35)', 'ErpColors.card')
content = content.replace('Color(0xFF252540)', 'ErpColors.bgWhite')
content = content.replace('Color(0xFF6C63FF)', 'ErpColors.primary')
content = content.replace('Colors.white12', 'ErpColors.border')
content = content.replace('Colors.white54', 'ErpColors.textMuted')
content = content.replace('Colors.white70', 'ErpColors.textSecondary')
content = content.replace('Colors.grey[850]', 'ErpColors.bgWhite')
content = content.replace('Colors.grey[900]', 'ErpColors.card')

# Let's replace TeacherColors.navy with ErpColors.primary
content = content.replace('TeacherColors.navy', 'ErpColors.primary')
# Let's replace TeacherColors.brass with ErpColors.accent
content = content.replace('TeacherColors.brass', 'ErpColors.accent')

# Special cases where Colors.white needs to be ErpColors.textPrimary
# Like in: style: TextStyle(color: Colors.white, ...
content = re.sub(r'color:\s*Colors\.white([^a-zA-Z0-9_]{1,4})', r'color: ErpColors.textPrimary\1', content)

# But wait, things inside AppBar, or primary colored containers need to be white.
# Typical places we need white:
# - Text inside ElevatedButton
# - DefaultTabController tabs (appBar) -> AppBar(backgroundColor: ErpColors.primary, foregroundColor: Colors.white)
# Let's just fix it if there's any huge visual bug.
# Better to do a more controlled replacement if we're not sure, but let's test it first.

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Basic replacements applied")
