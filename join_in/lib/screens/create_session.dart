import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/event_category.dart';
import '../services/session_service.dart';
import '../theme.dart';
import 'main_navigation.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final SessionService _sessions = SessionService();
  int _currentStep = 0;
  bool _isLoading = false;

  /// Currently selected catalog entry (or null until the user picks one).
  EventCategory? _selectedCategory;
  final _titleController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _slots = 10;
  int _minAttendees = 2;
  String _skillLevel = 'All Welcome';

  @override
  void dispose() {
    _titleController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publishEvent() async {
    final category = _selectedCategory;
    final title = _titleController.text.trim();
    if (category == null ||
        title.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: const Text('Please fill out category, title, date, and time.'),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    // The backend enforces `dateTime > now`. If the user picked today + a
    // time-of-day that's already passed (or even a minute in the past after
    // tapping through the wizard), the create returns a generic 422 with
    // little detail — catch it here so the error is obvious in-app.
    if (!dt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: const Text(
            'Pick a date and time that is in the future (at least a few minutes from now).'),
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final venueName = _venueNameController.text.trim().isEmpty
          ? 'TBD'
          : _venueNameController.text.trim();
      final venueAddress = _venueAddressController.text.trim();
      final description = _descriptionController.text.trim();
      final body = <String, dynamic>{
        'title': title,
        // Backend stores this as `activityType`; from the user's perspective
        // it's just "the event category" (sports, music, outdoors, ...).
        'activityType': category.id,
        'venue': {
          'name': venueName,
          // The backend's Joi schema treats `address` as a required non-empty
          // string. Falling back to the venue name keeps the request valid
          // while still giving the user something sensible to display.
          'address': venueAddress.isEmpty ? venueName : venueAddress,
          // GeoJSON [lng, lat] — must be doubles so the backend's
          // `number().min(...).max(...)` precision checks pass cleanly.
          'coordinates': {
            'type': 'Point',
            'coordinates': <double>[0.0, 0.0],
          },
        },
        'dateTime': dt.toUtc().toIso8601String(),
        'totalSlots': _slots,
        // Backend key is still `minPlayers`; surfaced as "min attendees".
        'minPlayers': _minAttendees,
        'skillLevel': _skillLevel == 'All Welcome' ? 'Beginner' : _skillLevel,
        'isPublic': true,
      };
      // Description is optional on the backend; only send it when non-empty
      // so we don't trip a `string().min(1)` validator with `""`.
      if (description.isNotEmpty) {
        body['description'] = description;
      }
      await _sessions.create(body);
      if (!mounted) return;
      // Pop any modal routes that may be sitting on top of MainNavigation
      // (date / time pickers, bottom sheets) before switching tabs.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.primaryAccent,
        content: Text('Event published!',
            style: TextStyle(
                color: AppTheme.darkBackground, fontWeight: FontWeight.bold)),
      ));
      // Jump to the Home tab. MainNavigation now keeps tabs alive via
      // IndexedStack, but switchTo(0) explicitly asks the Home feed to do a
      // silent refresh so the brand-new event appears at the top.
      MainNavigation.of(context)?.switchTo(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString()),
        duration: const Duration(seconds: 6),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: context.cs.surfaceContainerLow,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 4) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep++);
                } else {
                  _publishEvent();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : details.onStepContinue,
                          child: _isLoading && _currentStep == 4
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: AppTheme.darkBackground))
                              : Text(_currentStep == 4
                                  ? 'Publish Event'
                                  : 'Continue'),
                        ),
                      ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading ? null : details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Category & Title',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick a category',
                            style: TextStyle(
                                color: context.cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.4)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: EventCategory.catalog
                              .map((c) => _CategoryPickerChip(
                                    category: c,
                                    selected: _selectedCategory?.id == c.id,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                          () => _selectedCategory = c);
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Event title',
                            hintText:
                                'e.g. Sunday football, Open-mic night, Sunset hike',
                          ),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Location',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _venueNameController,
                          decoration: const InputDecoration(
                              labelText: 'Venue name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _venueAddressController,
                          decoration: const InputDecoration(
                              labelText: 'Address (optional)'),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Date & Time',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _pickerTile(
                            icon: Icons.calendar_today,
                            iconColor: AppTheme.primaryAccent,
                            label: _selectedDate == null
                                ? 'Select date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now()
                                    .add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 60)),
                              );
                              if (d != null) {
                                setState(() => _selectedDate = d);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pickerTile(
                            icon: Icons.access_time,
                            iconColor: AppTheme.secondaryAccent,
                            label: _selectedTime == null
                                ? 'Select time'
                                : _selectedTime!.format(context),
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                      hour: 18, minute: 0));
                              if (t != null) {
                                setState(() => _selectedTime = t);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Capacity & Level',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        _buildStepperRow('Total Spots', _slots,
                            (val) => setState(() => _slots = val),
                            min: 2, max: 50),
                        const SizedBox(height: 12),
                        _buildStepperRow('Min Attendees', _minAttendees,
                            (val) => setState(() => _minAttendees = val),
                            min: 2, max: _slots),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _skillLevel,
                          decoration: const InputDecoration(
                            labelText: 'Experience level',
                          ),
                          items: const [
                            'Beginner',
                            'Intermediate',
                            'Advanced',
                            'All Welcome'
                          ]
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _skillLevel = val ?? 'All Welcome'),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Description',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Tell people what to expect',
                      ),
                    ),
                  ),
                  isActive: _currentStep >= 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cs.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperRow(
    String label,
    int value,
    void Function(int) onChanged, {
    required int min,
    required int max,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Row(
            children: [
              IconButton(
                  icon: Icon(Icons.remove_circle,
                      color: value > min
                          ? context.cs.onSurface
                          : context.cs.onSurfaceVariant),
                  onPressed: value > min
                      ? () {
                          HapticFeedback.selectionClick();
                          onChanged(value - 1);
                        }
                      : null),
              SizedBox(
                  width: 36,
                  child: Center(
                      child: Text('$value',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)))),
              IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: AppTheme.primaryAccent),
                  onPressed: value < max
                      ? () {
                          HapticFeedback.selectionClick();
                          onChanged(value + 1);
                        }
                      : null),
            ],
          )
        ],
      ),
    );
  }
}

/// Pill chip rendered inside the "Category & Title" step. Shows the catalog
/// emoji + label and visually fills with the category color when picked, so
/// the user always knows what theme their event will adopt across the app.
class _CategoryPickerChip extends StatelessWidget {
  const _CategoryPickerChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.18)
              : context.cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? category.color : context.cs.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(category.label,
                style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? category.color
                        : context.cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
