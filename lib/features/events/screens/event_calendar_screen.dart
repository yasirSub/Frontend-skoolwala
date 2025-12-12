import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/event_service.dart';
import 'create_event_screen.dart';

/// Event Calendar Screen
/// Shows events in a calendar view
class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await EventService.getEvents();
      final eventsMap = <DateTime, List<Event>>{};

      for (var event in events) {
        final date = DateTime.parse(event.startDate).toLocal();
        final dateKey = DateTime(date.year, date.month, date.day);

        if (!eventsMap.containsKey(dateKey)) {
          eventsMap[dateKey] = [];
        }
        eventsMap[dateKey]!.add(event);
      }

      setState(() {
        _events = eventsMap;
        _selectedEvents = _getEventsForDay(_selectedDay);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ).then((_) => _loadEvents());
            },
            tooltip: 'Create Event',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadEvents,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Calendar View (Simplified)
                _buildCalendarView(),
                const Divider(),
                // Events List
                Expanded(
                  child: _selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No events for this day',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(_selectedEvents[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.event, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(DateTime.parse(event.startDate)),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showEventDetails(event);
        },
      ),
    );
  }

  Widget _buildCalendarView() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          // Date Picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDay = date;
                    _selectedEvents = _getEventsForDay(date);
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDay),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.description != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(event.description!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Date & Time:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat(
                  'MMMM dd, yyyy • hh:mm a',
                ).format(DateTime.parse(event.startDate)),
              ),
              if (event.location != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(event.location!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Event Model
class Event {
  final String id;
  final String title;
  final String? description;
  final String startDate;
  final String? endDate;
  final String? location;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['event_title']?.toString() ?? '',
      description: json['description']?.toString(),
      startDate:
          json['start_date']?.toString() ?? json['date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
      location: json['location']?.toString(),
    );
  }
}
