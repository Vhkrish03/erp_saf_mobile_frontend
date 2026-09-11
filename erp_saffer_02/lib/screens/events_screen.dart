import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../teacher/models/event_model.dart';
import '../teacher/services/event_service.dart';
import '../teacher/widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  final bool embedded;
  final String studentId;

  const EventsScreen({
    super.key,
    this.embedded = false,
    this.studentId = "STU25",
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  late Future<List<EventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _eventService.getEventsForUser(
        widget.studentId,
        "STUDENT",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: ErpColors.primary,
      elevation: 0,
      leading:
          widget.embedded
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
      title: Text(
        'Campus Events',
        style: ErpTypography.titleLarge.copyWith(color: ErpColors.accent),
      ),
    );

    final eventsBody = RefreshIndicator(
      color: ErpColors.primary,
      onRefresh: () async {
        _loadEvents();
        await _eventsFuture;
      },
      child: FutureBuilder<List<EventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: ErpSpacing.pagePadding,
              children: const [
                ErpSkeletonCard(),
                SizedBox(height: 12),
                ErpSkeletonCard(),
                SizedBox(height: 12),
                ErpSkeletonCard(),
              ],
            );
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 90),
                ErpErrorState(message: 'We could not retrieve campus events right now.', onRetry: _loadEvents),
              ],
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                ErpEmptyState(
                  message: 'No upcoming events',
                  subtitle: 'There are no campus events available for your profile right now.',
                  icon: Icons.event_available_outlined,
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              return EventCard(
                event: ev,
                currentRole: "STUDENT",
                currentEmployeeId: widget.studentId,
                onRefresh: _loadEvents,
              );
            },
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: appBar,
      body: eventsBody,
    );
  }
}
