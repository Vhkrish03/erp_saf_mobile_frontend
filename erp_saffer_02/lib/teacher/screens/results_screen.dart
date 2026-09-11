import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../models/student_summary.dart';
import '../services/result_service.dart';
import '../theme/teacher_theme.dart';

class ResultsScreen extends StatefulWidget {
  final String employeeId;
  const ResultsScreen({super.key, required this.employeeId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ResultService _service = ResultService();

  String _semester = 'III';
  String _section = 'A';
  String _subject = 'Data Structures';

  final _semesters = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
  final _sections = ['A', 'B', 'C'];
  final _subjects = [
    'Data Structures',
    'Database Management Systems',
    'Operating Systems',
    'Computer Networks',
  ];

  List<ResultEntry> _entries = [];
  bool _loading = true;
  bool _saving = false;
  bool _publishing = false;
  String? _errorMessage;

  final Map<String, TextEditingController> _internalControllers = {};
  final Map<String, TextEditingController> _externalControllers = {};

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  @override
  void dispose() {
    for (final c in _internalControllers.values) {
      c.dispose();
    }
    for (final c in _externalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final entries = await _service.getStudentsForResults(
        semester: _semester,
        section: _section,
        subject: _subject,
      );
    _internalControllers.clear();
    _externalControllers.clear();
    for (final e in entries) {
      _internalControllers[e.studentId] = TextEditingController(
        text: e.internalMarks == 0 ? '' : e.internalMarks.toString(),
      );
      _externalControllers[e.studentId] = TextEditingController(
        text: e.externalMarks == 0 ? '' : e.externalMarks.toString(),
      );
    }
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'We could not retrieve the result roster right now.';
        });
      }
    }
  }

  void _recalculateGrade(ResultEntry entry) {
    final internal =
        double.tryParse(_internalControllers[entry.studentId]?.text ?? '') ?? 0;
    final external =
        double.tryParse(_externalControllers[entry.studentId]?.text ?? '') ?? 0;
    setState(() {
      entry.internalMarks = internal;
      entry.externalMarks = external;
      entry.grade = ResultEntry.calculateGrade(internal, external);
    });
  }

  Future<void> _saveResults() async {
    setState(() => _saving = true);
    final success = await _service.saveResults(
      semester: _semester,
      section: _section,
      subject: _subject,
      entries: _entries,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showSnack(
      success ? 'Results saved as draft.' : 'Failed to save results.',
      success,
    );
  }

  Future<void> _publishResults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Publish Results'),
            content: const Text(
              'Once published, results will be visible to students immediately. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Publish'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _publishing = true);
    final success = await _service.publishResults(
      semester: _semester,
      section: _section,
      subject: _subject,
    );
    if (!mounted) return;
    setState(() => _publishing = false);
    _showSnack(
      success
          ? 'Results published successfully.'
          : 'Failed to publish results.',
      success,
    );
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? TeacherColors.success : TeacherColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: TeacherDecorations.card(),
                child: Row(
                  children: [
                    Expanded(
                      child: _Dropdown(
                        label: 'Semester',
                        value: _semester,
                        items: _semesters,
                        onChanged: (v) => setState(() => _semester = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Dropdown(
                        label: 'Section',
                        value: _section,
                        items: _sections,
                        onChanged: (v) => setState(() => _section = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _Dropdown(
                        label: 'Subject',
                        value: _subject,
                        items: _subjects,
                        onChanged: (v) => setState(() => _subject = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadRoster,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Load Roster'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _loading
                      ? const _ResultsRosterSkeleton()
                      : _errorMessage != null
                      ? ErpErrorState(message: _errorMessage!, onRetry: _loadRoster)
                      : _entries.isEmpty
                      ? const ErpEmptyState(
                        message: 'No students in this roster',
                        subtitle: 'Try another semester, section, or subject.',
                        icon: Icons.groups_outlined,
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                        itemCount: _entries.length,
                        itemBuilder: (context, i) {
                          final e = _entries[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: TeacherDecorations.card(radius: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.studentName,
                                            style: TeacherTextStyles.heading3,
                                          ),
                                          Text(
                                            e.rollNumber,
                                            style: TeacherTextStyles.bodyMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    _GradeBadge(grade: e.grade),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            _internalControllers[e.studentId],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Internal Marks',
                                          isDense: true,
                                        ),
                                        onChanged: (_) => _recalculateGrade(e),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            _externalControllers[e.studentId],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'External Marks',
                                          isDense: true,
                                        ),
                                        onChanged: (_) => _recalculateGrade(e),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _saveResults,
                      child:
                          _saving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _publishing ? null : _publishResults,
                      child:
                          _publishing
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Publish Result'),
                    ),
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

class _ResultsRosterSkeleton extends StatelessWidget {
  const _ResultsRosterSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final String grade;
  const _GradeBadge({required this.grade});

  Color get _color {
    switch (grade) {
      case 'O':
      case 'A+':
        return TeacherColors.success;
      case 'A':
      case 'B+':
        return TeacherColors.brass;
      case 'RA':
        return TeacherColors.danger;
      default:
        return TeacherColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TeacherTextStyles.label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TeacherColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items:
                  items
                      .map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(i, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
