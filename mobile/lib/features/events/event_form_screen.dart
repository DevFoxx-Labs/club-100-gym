import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/event_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../core/utils/form_validators.dart';
import '../../core/services/app_state_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;
  final DateTime? initialDate;

  const EventFormScreen({super.key, this.event, this.initialDate});

  bool get isEdit => event != null;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  final EventRepository _eventRepository = EventRepository();
  final TrainerRepository _trainerRepository = TrainerRepository();

  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);
  String? _selectedTrainerId;
  List<TrainerModel> _trainers = [];
  Color _color = const Color(0xFFD4FF00);
  bool _isLoading = false;

  final List<Color> _presetColors = const [
    Color(0xFFD4FF00), // Neon Lime
    Color(0xFF00E676), // Neon Green
    Color(0xFF00E5FF), // Cyan / Electric Blue
    Color(0xFFFF9100), // Vibrant Orange
    Color(0xFFFF5252), // Coral Red
    Color(0xFFE040FB), // Electric Purple
    Color(0xFFFF4081), // Hot Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      final e = widget.event!;
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      final start = DateTime.parse(e.startTime);
      final end = DateTime.parse(e.endTime);
      _date = DateTime(start.year, start.month, start.day);
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
      _selectedTrainerId = e.trainerId;
      _color = e.colorValue != null ? Color(e.colorValue!) : const Color(0xFFD4FF00);
    } else {
      final now = DateTime.now();
      _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
      final nextHour = (now.hour + 1) % 24;
      _startTime = TimeOfDay(hour: nextHour, minute: 0);
      _endTime = TimeOfDay(hour: (nextHour + 1) % 24, minute: 0);
    }
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    final trainers = await _trainerRepository.getAllTrainers();
    if (mounted) setState(() => _trainers = trainers);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4FF00),
            onPrimary: Color(0xFF121212),
            surface: Color(0xFF1E1E1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4FF00),
            onPrimary: Color(0xFF121212),
            surface: Color(0xFF1E1E1E),
          ),
        ),
        child: child!,
      ),
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

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = _combineDateAndTime(_date, _startTime);
    final endDateTime = _combineDateAndTime(_date, _endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time'), backgroundColor: Color(0xFFFF5252)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final now = DateTime.now().toIso8601String();
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final location = _locationController.text.trim();

    if (widget.isEdit) {
      final updated = widget.event!.copyWith(
        title: title,
        description: desc.isEmpty ? null : desc,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
        location: location.isEmpty ? null : location,
        trainerId: _selectedTrainerId,
        colorValue: _color.toARGB32(),
        updatedAt: now,
      );
      await _eventRepository.updateEvent(updated);
      await NotificationService().scheduleEventNotification(updated);
    } else {
      final newEvent = EventModel(
        id: const Uuid().v4(),
        title: title,
        description: desc.isEmpty ? null : desc,
        startTime: startDateTime.toIso8601String(),
        endTime: endDateTime.toIso8601String(),
        location: location.isEmpty ? null : location,
        trainerId: _selectedTrainerId,
        colorValue: _color.toARGB32(),
        createdAt: now,
        updatedAt: now,
      );
      await _eventRepository.insertEvent(newEvent);
      await NotificationService().scheduleEventNotification(newEvent);
    }

    AppStateService.instance.notifyEventsChanged();

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Delete Event?',
        message: 'Are you sure you want to remove this scheduled event?',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      await NotificationService().cancelEventNotification(widget.event!.id);
      await _eventRepository.deleteEvent(widget.event!.id);
      AppStateService.instance.notifyEventsChanged();
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'EDIT EVENT' : 'ADD EVENT',
          style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
              onPressed: _deleteEvent,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'EVENT / CLASS TITLE *',
                hint: 'e.g. Morning HIIT, CrossFit Bootcamp, Yoga Flow',
                controller: _titleController,
                validator: (v) => FormValidators.validateName(v, fieldName: 'Event title'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'LOCATION / ZONE (OPTIONAL)',
                hint: 'e.g. Studio 2, Main Weight Floor, Turf Area',
                controller: _locationController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'DESCRIPTION (OPTIONAL)',
                hint: 'Notes on equipment needed, target audience, or instructions',
                controller: _descController,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Date Picker Tile
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, color: Color(0xFFD4FF00)),
                  title: const Text('Event Date', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  subtitle: Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(_date),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),

              // Time Pickers Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        leading: const Icon(Icons.schedule, color: Color(0xFFD4FF00), size: 20),
                        title: const Text('Start Time', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        subtitle: Text(
                          _startTime.format(context),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        leading: const Icon(Icons.schedule, color: Color(0xFFD4FF00), size: 20),
                        title: const Text('End Time', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        subtitle: Text(
                          _endTime.format(context),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Trainer Assignment Dropdown
              const Text(
                'INSTRUCTOR / TRAINER',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedTrainerId,
                dropdownColor: const Color(0xFF252525),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Select Trainer (Optional)',
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFFD4FF00)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Trainer Assigned')),
                  ..._trainers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                ],
                onChanged: (val) => setState(() => _selectedTrainerId = val),
              ),
              const SizedBox(height: 24),

              // Color Preset Selector
              const Text(
                'EVENT COLOR ACCENT',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: _presetColors.map((color) {
                  final isSelected = _color.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 18, color: Color(0xFF121212)) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Save Button
              NeonButton(
                text: widget.isEdit ? 'Save Changes' : 'Schedule Event',
                icon: Icons.check,
                isLoading: _isLoading,
                width: double.infinity,
                onPressed: _saveEvent,
              ),
              SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    ),
  );
}
}

