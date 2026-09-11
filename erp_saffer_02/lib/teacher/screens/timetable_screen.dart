import 'package:flutter/material.dart';
import '../../models/Timetable_model.dart';
import '../services/timetable_service.dart';
import '../theme/teacher_theme.dart';
import '../widgets/teacher_schedule_card.dart';

class TimetableScreen extends StatefulWidget {
  final String employeeId;
  const TimetableScreen({super.key, required this.employeeId});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<TimetableModel>> _timetableFuture;

  final TeacherTimetableService _service =
  TeacherTimetableService();

  @override
  void initState() {
    super.initState();
    _timetableFuture = _service.getTeacherTimetable(widget.employeeId);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.parchment,
      appBar: AppBar(
        title: const Text('Timetable'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: TeacherColors.navy,
          unselectedLabelColor: TeacherColors.textSecondary,
          indicatorColor: TeacherColors.brass,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Weekly')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(future: _timetableFuture),
          _WeeklyTab(future: _timetableFuture),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  final Future<List<TimetableModel>> future;
  const _TodayTab({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TimetableModel>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: TeacherColors.navy));
        }
        final slots = snapshot.data!;
        if (slots.isEmpty) {
          return const Center(child: Text('No classes scheduled for today.'));
        }
        return ListView(
          padding: const EdgeInsets.all(18),
          children: slots.map((s) => TeacherScheduleCard(slot: s)).toList(),
        );
      },
    );
  }
}

class _WeeklyTab extends StatelessWidget {
  final Future<List<TimetableModel>> future;

  const _WeeklyTab({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TimetableModel>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: TeacherColors.navy,
            ),
          );
        }

        final timetable = snapshot.data!;

        Map<String, List<TimetableModel>> grouped = {};

        for (var slot in timetable) {
          grouped.putIfAbsent(slot.day, () => []);
          grouped[slot.day]!.add(slot);
        }

        final days = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: days.length,
          itemBuilder: (context, i) {
            final day = days[i];
            final slots = grouped[day]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day, style: TeacherTextStyles.heading2),
                  const SizedBox(height: 10),

                  if (slots.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: TeacherDecorations.card(),
                      child: const Text(
                        'No classes.',
                        style: TeacherTextStyles.bodyMuted,
                      ),
                    )
                  else
                    ...slots.map(
                          (s) => TeacherScheduleCard(slot: s),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
