import 'package:flutter/material.dart';

import '../services/assignment_service.dart';
import '../theme/teacher_theme.dart';

class CreateAssignmentSheet extends StatefulWidget {
  final AssignmentService service;
  final VoidCallback onCreated;
  final String employeeId;

  const CreateAssignmentSheet({
    super.key,
    required this.service,
    required this.onCreated,
    required this.employeeId,
  });

  @override
  State<CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<CreateAssignmentSheet> {
  final _titleController = TextEditingController();

  final _descriptionController = TextEditingController();

  DateTime? _dueDate;

  String _year = "III";

  String _department = "CSE";

  String _section = "A";

  String? _attachmentFileName;

  bool _submitting = false;

  final List<String> _years = ["I", "II", "III", "IV"];

  final List<String> _departments = ["CSE", "EEE", "AIDS", "ECE", "BIOTECH"];

  final List<String> _sections = ["A", "B"];

  @override
  void dispose() {
    _titleController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate: DateTime.now().add(const Duration(days: 7)),

      firstDate: DateTime.now(),

      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _pickAttachment() {
    // Replace later with file_picker

    setState(() {
      _attachmentFileName = "assignment_brief.pdf";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PDF attached successfully")));
  }

  Future<void> _publish() async {
    if (_titleController.text
        .trim()
        .isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter title and due date")));

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.service.createAssignment(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate!,
        department: _department,
        year: _year,
        section: _section,
        attachmentFileName: _attachmentFileName,
        createdBy: widget.employeeId,
      );

      widget.onCreated();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assignment published successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),

      decoration: const BoxDecoration(
        color: TeacherColors.parchment,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                height: 4,

                width: 45,

                decoration: BoxDecoration(
                  color: TeacherColors.divider,

                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Create Assignment", style: TeacherTextStyles.heading1),

            const SizedBox(height: 20),

            _sectionTitle("Assignment Details"),

            TextField(
              controller: _titleController,

              decoration: _inputDecoration("Assignment Title", Icons.title),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,

              maxLines: 4,

              decoration: _inputDecoration(
                "Description",
                Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Target Students"),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 140,
                  child: _buildDropdown(
                    label: "Year",
                    value: _year,
                    items: _years,
                    onChanged: (v) {
                      setState(() => _year = v!);
                    },
                  ),
                ),

                SizedBox(
                  width: 140,
                  child: _buildDropdown(
                    label: "Department",
                    value: _department,
                    items: _departments,
                    onChanged: (v) {
                      setState(() => _department = v!);
                    },
                  ),
                ),

                SizedBox(
                  width: 140,
                  child: _buildDropdown(
                    label: "Section",
                    value: _section,
                    items: _sections,
                    onChanged: (v) {
                      setState(() => _section = v!);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _sectionTitle("Submission Details"),

            OutlinedButton.icon(
              onPressed: _pickDueDate,

              icon: const Icon(Icons.calendar_month),

              label: Text(
                _dueDate == null
                    ? "Select Due Date"
                    : "${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}",
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickAttachment,

              icon: const Icon(Icons.attach_file),

              label: Text(_attachmentFileName ?? "Upload PDF"),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _submitting ? null : _publish,

                child: _submitting
                    ? const SizedBox(
                  height: 20,

                  width: 20,

                  child: CircularProgressIndicator(
                    strokeWidth: 2,

                    color: Colors.white,
                  ),
                )
                    : const Text("Publish Assignment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeacherColors.divider),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          // isExpanded: true,

          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Text(
        title,

        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _inputDecoration(String text, IconData icon) {
    return InputDecoration(
      labelText: text,

      prefixIcon: Icon(icon),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: BorderSide.none,
      ),
    );
  }
}