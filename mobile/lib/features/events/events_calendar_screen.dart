import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../core/services/app_state_service.dart';
import '../../core/notifications/notification_service.dart';
import 'event_form_screen.dart';

class EventsCalendarScreen extends StatefulWidget {
  const EventsCalendarScreen({super.key});

  @override
  State<EventsCalendarScreen> createState() => _EventsCalendarScreenState();
}

class _EventsCalendarScreenState extends State<EventsCalendarScreen> {
  final EventRepository _repository = EventRepository();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  List<EventModel> _monthEvents = [];
  List<EventModel> _selectedDateEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadEvents(showSpinner: false);
    }
  }

  Future<void> _loadEvents({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }
    final events = await _repository.getEventsForMonth(_currentMonth.year, _currentMonth.month);
    final dayEvents = await _repository.getEventsForDate(_selectedDate);
    if (mounted) {
      setState(() {
        _monthEvents = events;
        _selectedDateEvents = dayEvents;
        _isLoading = false;
      });
    }
    NotificationService().syncAllUpcomingEventNotifications();
  }

  void _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    final dayEvents = await _repository.getEventsForDate(date);
    if (mounted) {
      setState(() {
        _selectedDateEvents = dayEvents;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'GYM EVENTS & SCHEDULE',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Month Header Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFFD4FF00)),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFFD4FF00)),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Calendar Grid
          _buildCalendarMonth(),

          const Divider(height: 1, color: Color(0xFF252525)),

          // Selected Day Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_selectedDate).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD4FF00),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${_selectedDateEvents.length} events',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Events List for Selected Day
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
                : _selectedDateEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            const Text(
                              'No events or classes scheduled for this day',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: _selectedDateEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final event = _selectedDateEvents[index];
                          return _buildEventCard(event);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventFormScreen(initialDate: _selectedDate)),
          );
          if (res == true) _loadEvents();
        },
        backgroundColor: const Color(0xFFD4FF00),
        icon: const Icon(Icons.add, color: Color(0xFF121212)),
        label: const Text(
          'Add Event',
          style: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCalendarMonth() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      color: const Color(0xFF181818),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Weekday initials
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((w) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          w,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 weeks
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (startWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = dayOffset + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              // Check if any event falls on this date
              final hasEvents = _monthEvents.any((e) {
                final start = DateTime.parse(e.startTime);
                return start.year == date.year && start.month == date.month && start.day == date.day;
              });

              return GestureDetector(
                onTap: () => _onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD4FF00)
                        : isToday
                            ? const Color(0xFF252525)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.6))
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF121212)
                              : isToday
                                  ? const Color(0xFFD4FF00)
                                  : Colors.white,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (hasEvents)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF121212) : const Color(0xFFD4FF00),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final start = DateTime.parse(event.startTime);
    final end = DateTime.parse(event.endTime);
    final timeStr = '${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}';
    final color = event.colorValue != null ? Color(event.colorValue!) : const Color(0xFFD4FF00);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
          );
          if (res == true) _loadEvents();
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_filled, size: 11, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (event.description != null && event.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description!.trim(),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (event.location != null && event.location!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: color.withValues(alpha: 0.85)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!.trim(),
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: Icon(Icons.arrow_forward_ios, size: 13, color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

