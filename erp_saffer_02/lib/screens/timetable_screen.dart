import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../models/timetable_model.dart';
import '../services/timetable_service.dart';

class TimetableScreen extends StatefulWidget {
  final bool embedded;
  const TimetableScreen({super.key, this.embedded = false});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  late int _selected;
  final TimetableService _service = TimetableService();
  List<TimetableModel> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    final todayIndex = DateTime.now().weekday - 1;

    _selected =
    (todayIndex >= 0 && todayIndex < _days.length)
        ? todayIndex
        : 0;

    loadTimetable();
  }

  Future<void> loadTimetable() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getTimetableByDay(_days[_selected]);

      setState(() {
        _slots = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'We could not retrieve the timetable right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final selected = i == _selected;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selected = i;
                  });

                  loadTimetable();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 64,
                  decoration: BoxDecoration(
                    color: selected ? ErpColors.primary : ErpColors.bgWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? ErpColors.primary : ErpColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _days[i].substring(0, 3),
                    style: TextStyle(
                      color: selected ? Colors.white : ErpColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const _TimetableSkeleton()
              : _error != null
              ? ErpErrorState(message: _error!, onRetry: loadTimetable)
              : slots.isEmpty
              ? const ErpEmptyState(
                  message: 'No classes scheduled',
                  subtitle: 'There are no timetable entries for this day.',
                  icon: Icons.event_busy_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = slots[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ErpColors.bgWhite,
                        borderRadius: ErpRadius.cardSm,
                        border: Border.all(color: ErpColors.border),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 78,
                            child: Text(s.time,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Container(width: 1, height: 34, color: ErpColors.divider, margin: const EdgeInsets.symmetric(horizontal: 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.subject, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text('${s.room} · ${s.faculty}', style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: ErpColors.bg,
        appBar: AppBar(title: const Text('Timetable'), automaticallyImplyLeading: false),
        body: SafeArea(child: body),
      );
    }

    return Scaffold(
      backgroundColor: ErpColors.bg,
      appBar: AppBar(title: const Text('Timetable')),
      body: body,
    );
  }
}

class _TimetableSkeleton extends StatelessWidget {
  const _TimetableSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: const [
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
        ErpSkeletonListItem(),
      ],
    );
  }
}
