import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../teacher/theme/teacher_theme.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_create_screen.dart';

class EventManagementScreen extends StatefulWidget {
  final String employeeId;
  final String role; // "FACULTY" or "HOD"

  const EventManagementScreen({
    Key? key,
    required this.employeeId,
    required this.role,
  }) : super(key: key);

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: ErpSpacing.pagePadding,
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}

class _EventManagementScreenState extends State<EventManagementScreen>
    with SingleTickerProviderStateMixin {
  final _eventService = EventService();
  TabController? _tabController;

  late Future<List<EventModel>> _myEventsFuture;
  late Future<List<EventModel>> _pendingApprovalsFuture;
  late Future<List<EventModel>> _publishedEventsFuture;

  @override
  void initState() {
    super.initState();
    final isHOD = widget.role.toUpperCase() == 'HOD';
    _tabController = TabController(length: isHOD ? 3 : 2, vsync: this);
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _myEventsFuture = _eventService.getMyEvents(
        widget.employeeId,
        widget.role,
      );
      _publishedEventsFuture = _eventService.getPublishedEvents();
      if (widget.role.toUpperCase() == 'HOD') {
        _pendingApprovalsFuture = _eventService.getPendingApprovals(
          widget.employeeId,
          widget.role,
        );
      } else {
        _pendingApprovalsFuture = Future.value([]);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _refreshMyEvents() async {
    setState(() {
      _myEventsFuture = _eventService.getMyEvents(
        widget.employeeId,
        widget.role,
      );
    });
    await _myEventsFuture;
  }

  Future<void> _refreshApprovals() async {
    setState(() {
      _pendingApprovalsFuture = _eventService.getPendingApprovals(
        widget.employeeId,
        widget.role,
      );
    });
    await _pendingApprovalsFuture;
  }

  Future<void> _refreshAllEvents() async {
    setState(() {
      _publishedEventsFuture = _eventService.getPublishedEvents();
    });
    await _publishedEventsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final isHOD = widget.role.toUpperCase() == 'HOD';

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(
        backgroundColor: TeacherColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Event Management",
          style: TextStyle(
            color: TeacherColors.brass,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TeacherColors.brass,
          labelColor: TeacherColors.brass,
          unselectedLabelColor: Colors.white70,
          tabs:
              isHOD
                  ? const [
                    Tab(text: "My Events"),
                    Tab(text: "Pending Approvals"),
                    Tab(text: "Campus Events"),
                  ]
                  : const [Tab(text: "My Events"), Tab(text: "Campus Events")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            isHOD
                ? [
                  _buildMyEventsList(),
                  _buildPendingApprovalsList(),
                  _buildAllEventsList(),
                ]
                : [_buildMyEventsList(), _buildAllEventsList()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TeacherColors.navy,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => EventCreateScreen(
                    employeeId: widget.employeeId,
                    role: widget.role,
                  ),
            ),
          );
          if (result == true) {
            _loadEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyEventsList() {
    return RefreshIndicator(
      color: TeacherColors.navy,
      onRefresh: _refreshMyEvents,
      child: FutureBuilder<List<EventModel>>(
        future: _myEventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _EventsSkeleton();
          }
          if (snapshot.hasError) {
            return const ErpErrorState(
              message: 'We could not retrieve events right now.',
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No events created yet.\nTap '+' to create your first announcement.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TeacherColors.textSecondary),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                currentRole: widget.role,
                currentEmployeeId: widget.employeeId,
                onRefresh: _loadEvents,
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => EventCreateScreen(
                            employeeId: widget.employeeId,
                            role: widget.role,
                            eventToEdit: event,
                          ),
                    ),
                  );
                  if (result == true) {
                    _loadEvents();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingApprovalsList() {
    return RefreshIndicator(
      color: TeacherColors.navy,
      onRefresh: _refreshApprovals,
      child: FutureBuilder<List<EventModel>>(
        future: _pendingApprovalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: TeacherColors.navy),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading approvals: ${snapshot.error}",
                style: const TextStyle(color: TeacherColors.danger),
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No pending event approvals in your department.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TeacherColors.textSecondary),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                currentRole: widget.role,
                currentEmployeeId: widget.employeeId,
                onRefresh: _loadEvents,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAllEventsList() {
    return RefreshIndicator(
      color: TeacherColors.navy,
      onRefresh: _refreshAllEvents,
      child: FutureBuilder<List<EventModel>>(
        future: _publishedEventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: TeacherColors.navy),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading campus events: ${snapshot.error}",
                style: const TextStyle(color: TeacherColors.danger),
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No campus events published yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TeacherColors.textSecondary),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                currentRole: widget.role,
                currentEmployeeId: widget.employeeId,
                onRefresh: _loadEvents,
              );
            },
          );
        },
      ),
    );
  }
}
