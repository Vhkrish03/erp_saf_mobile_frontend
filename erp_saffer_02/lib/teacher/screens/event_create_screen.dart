import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import '../../teacher/theme/teacher_theme.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventCreateScreen extends StatefulWidget {
  final String employeeId;
  final String role; // "FACULTY" or "HOD"
  final EventModel? eventToEdit; // If editing draft or rejected event

  const EventCreateScreen({
    Key? key,
    required this.employeeId,
    required this.role,
    this.eventToEdit,
  }) : super(key: key);

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();

  bool _isLoading = false;
  String? _userName;
  String? _userDept;

  // Form Fields Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgDeptController = TextEditingController();
  final _venueController = TextEditingController();
  final _regLinkController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _eligibilityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _attachmentUrlController = TextEditingController();

  String _eventType = "COLLEGE_EVENT"; // "COLLEGE_EVENT" or "EXTERNAL_EVENT"
  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _regRequired = false;
  DateTime? _regStartDate;
  DateTime? _regEndDate;

  String _targetAudience = "ALL"; // "ALL", "STUDENTS", "TEACHERS"
  String _targetDept = "ALL";
  String _targetYear = "ALL";
  String _targetSection = "ALL";

  final List<String> _departments = [
    "ALL",
    "CSE",
    "ECE",
    "MECH",
    "CIVIL",
    "EEE",
    "IT",
  ];
  final List<String> _years = ["ALL", "1", "2", "3", "4"];
  final List<String> _sections = ["ALL", "A", "B", "C", "D"];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    if (widget.eventToEdit != null) {
      _prepopulateFields(widget.eventToEdit!);
    }
  }

  void _prepopulateFields(EventModel event) {
    _titleController.text = event.title;
    _descController.text = event.description;
    _eventType = event.eventType;
    _orgNameController.text = event.organizerName ?? '';
    _orgDeptController.text = event.organizerDepartment ?? '';
    _venueController.text = event.venue ?? '';
    _eventDate = event.eventDate;

    if (event.startTime != null) {
      final parts = event.startTime!.split(':');
      if (parts.length >= 2) {
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    if (event.endTime != null) {
      final parts = event.endTime!.split(':');
      if (parts.length >= 2) {
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    _regRequired = event.registrationRequired;
    _regLinkController.text = event.registrationLink ?? '';
    _regStartDate = event.registrationStartDate;
    _regEndDate = event.registrationEndDate;
    _contactPersonController.text = event.contactPerson ?? '';
    _contactEmailController.text = event.contactEmail ?? '';
    _contactPhoneController.text = event.contactPhone ?? '';
    _eligibilityController.text = event.eligibility ?? '';
    _targetAudience = event.targetAudience ?? 'ALL';
    _targetDept = event.department ?? 'ALL';
    _targetYear = event.year ?? 'ALL';
    _targetSection = event.section ?? 'ALL';
    _imageUrlController.text = event.imageUrl ?? '';
    _attachmentUrlController.text = event.attachmentUrl ?? '';
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.role.toUpperCase() == 'HOD') {
        final res = await http.get(
          Uri.parse("${ApiConstants.baseUrl}/api/hod/${widget.employeeId}"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _userName = data['name'];
            _userDept = data['department'];
            if (widget.eventToEdit == null) {
              _orgNameController.text = _userName ?? '';
              _orgDeptController.text = _userDept ?? '';
            }
          });
        }
      } else {
        final res = await http.get(
          Uri.parse("${ApiConstants.baseUrl}/api/teacher/${widget.employeeId}"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _userName = data['name'];
            _userDept = data['department'];
            if (widget.eventToEdit == null) {
              _orgNameController.text = _userName ?? '';
              _orgDeptController.text = _userDept ?? '';
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isEventDate,
    bool isRegStart,
  ) async {
    final DateTime initialDate =
        isEventDate
            ? (_eventDate ?? DateTime.now().add(const Duration(days: 1)))
            : (isRegStart
                ? (_regStartDate ?? DateTime.now())
                : (_regEndDate ?? DateTime.now().add(const Duration(days: 1))));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TeacherColors.navy,
              onPrimary: Colors.white,
              onSurface: TeacherColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEventDate) {
          _eventDate = picked;
        } else if (isRegStart) {
          _regStartDate = picked;
        } else {
          _regEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay initialTime =
        isStart
            ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
            : (_endTime ?? const TimeOfDay(hour: 17, minute: 0));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TeacherColors.navy,
              onPrimary: Colors.white,
              onSurface: TeacherColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? tod) {
    if (tod == null) return "";
    final hour = tod.hour.toString().padLeft(2, '0');
    final min = tod.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select the event date")),
      );
      return;
    }

    if (_regRequired) {
      if (_regStartDate != null &&
          _regEndDate != null &&
          _regEndDate!.isBefore(_regStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration end date cannot be before start date"),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final event = EventModel(
      id: widget.eventToEdit?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      eventType: _eventType,
      organizerName: _orgNameController.text.trim(),
      organizerDepartment: _orgDeptController.text.trim(),
      venue: _venueController.text.trim(),
      eventDate: _eventDate!,
      startTime: _startTime != null ? _formatTimeOfDay(_startTime) : "09:00",
      endTime: _endTime != null ? _formatTimeOfDay(_endTime) : "17:00",
      registrationRequired: _regRequired,
      registrationLink: _regRequired ? _regLinkController.text.trim() : null,
      registrationStartDate: _regRequired ? _regStartDate : null,
      registrationEndDate: _regRequired ? _regEndDate : null,
      contactPerson: _contactPersonController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      eligibility: _eligibilityController.text.trim(),
      targetAudience: _targetAudience,
      department: _targetDept,
      year: _targetYear,
      section: _targetSection,
      imageUrl: _imageUrlController.text.trim(),
      attachmentUrl: _attachmentUrlController.text.trim(),
      status: widget.eventToEdit?.status ?? "DRAFT",
    );

    try {
      if (widget.eventToEdit != null) {
        await _eventService.updateEvent(
          event.id!,
          event,
          widget.employeeId,
          widget.role,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event updated successfully")),
        );
      } else {
        await _eventService.createEvent(event, widget.employeeId, widget.role);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event created as dynamic DRAFT")),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Action failed: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText =
        widget.eventToEdit != null
            ? "Edit Event Announcement"
            : "Create Event Announcement";

    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        backgroundColor: TeacherColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
          style: const TextStyle(
            color: TeacherColors.brass,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading && _userName == null
              ? const Center(
                child: CircularProgressIndicator(color: TeacherColors.navy),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Basic Details ---
                      _sectionHeader("Basic Information"),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: "Event Title *",
                          hintText: "e.g. Hackathon 2026",
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? "Title is required"
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(fontSize: 14.5),
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Description *",
                          alignLabelWithHint: true,
                          hintText: "Enter complete details about the event...",
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 50.0),
                            child: Icon(Icons.description_outlined),
                          ),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? "Description is required"
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _eventType,
                        decoration: const InputDecoration(
                          labelText: "Event Type *",
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "COLLEGE_EVENT",
                            child: Text("College Event"),
                          ),
                          DropdownMenuItem(
                            value: "EXTERNAL_EVENT",
                            child: Text("External Event"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _eventType = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      // --- Date, Time & Venue ---
                      _sectionHeader("Scheduling & Location"),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () => _selectDate(context, true, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: TeacherColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: TeacherColors.navyLight,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _eventDate == null
                                    ? "Select Event Date *"
                                    : "Event Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color:
                                      _eventDate == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: TeacherColors.divider,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: TeacherColors.navyLight,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _startTime == null
                                            ? "Start Time"
                                            : _startTime!.format(context),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: TeacherColors.divider,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.done_all,
                                      color: TeacherColors.navyLight,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _endTime == null
                                            ? "End Time"
                                            : _endTime!.format(context),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _venueController,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: "Venue *",
                          hintText: "e.g. Auditorium / Lab 3",
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? "Venue is required"
                                    : null,
                      ),
                      const SizedBox(height: 24),

                      // --- Target Audience ---
                      _sectionHeader("Target Audience Filtering"),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _targetAudience,
                        decoration: const InputDecoration(
                          labelText: "Audience Category",
                          prefixIcon: Icon(Icons.people_alt_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "ALL",
                            child: Text("All (Students & Teachers)"),
                          ),
                          DropdownMenuItem(
                            value: "STUDENTS",
                            child: Text("Students Only"),
                          ),
                          DropdownMenuItem(
                            value: "TEACHERS",
                            child: Text("Teachers Only"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _targetAudience = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _targetDept,
                              decoration: const InputDecoration(
                                labelText: "Dept",
                              ),
                              items:
                                  _departments
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _targetDept = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _targetYear,
                              decoration: const InputDecoration(
                                labelText: "Year",
                              ),
                              items:
                                  _years
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text(y),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _targetYear = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _targetSection,
                              decoration: const InputDecoration(
                                labelText: "Section",
                              ),
                              items:
                                  _sections
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _targetSection = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Registration ---
                      _sectionHeader("Registration & Entry Details"),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        activeColor: TeacherColors.brass,
                        title: const Text(
                          "Registration Required",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TeacherColors.navy,
                          ),
                        ),
                        subtitle: const Text(
                          "Requires registration links and closing dates",
                        ),
                        value: _regRequired,
                        onChanged: (val) => setState(() => _regRequired = val),
                      ),
                      if (_regRequired) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _regLinkController,
                          style: const TextStyle(fontSize: 14.5),
                          decoration: const InputDecoration(
                            labelText: "Registration Link *",
                            hintText: "https://forms.gle/...",
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator:
                              (v) =>
                                  _regRequired &&
                                          (v == null || v.trim().isEmpty)
                                      ? "Registration link is required"
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: TeacherColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    _regStartDate == null
                                        ? "Reg Start Date"
                                        : "Start: ${_regStartDate!.day}/${_regStartDate!.month}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: TeacherColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    _regEndDate == null
                                        ? "Reg End Date"
                                        : "End: ${_regEndDate!.day}/${_regEndDate!.month}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // --- Contact Details ---
                      _sectionHeader("Contact Information"),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _contactPersonController,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: "Contact Person name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactEmailController,
                              style: const TextStyle(fontSize: 13.5),
                              decoration: const InputDecoration(
                                labelText: "Email",
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPhoneController,
                              style: const TextStyle(fontSize: 13.5),
                              decoration: const InputDecoration(
                                labelText: "Phone",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _eligibilityController,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: "Eligibility Criteria",
                          hintText: "e.g. Open to B.Tech ONLY",
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Visual Assets ---
                      _sectionHeader("Promotional Links"),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _imageUrlController,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: "Banner Image URL",
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _attachmentUrlController,
                        style: const TextStyle(fontSize: 14.5),
                        decoration: const InputDecoration(
                          labelText: "Attachment Link (PDF)",
                          prefixIcon: Icon(Icons.attach_file),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Organizer fields (Pre-filled read-only)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: TeacherColors.divider),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Creator Profile Attributes (Autofilled)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: TeacherColors.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Name: ${_userName ?? "Loading..."}"),
                            Text("Department: ${_userDept ?? "Loading..."}"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: TeacherColors.navy,
                            ),
                          )
                          : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  child: const Text("Save & Exit"),
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _sectionHeader(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: TeacherColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: TeacherColors.divider),
      ],
    );
  }
}
