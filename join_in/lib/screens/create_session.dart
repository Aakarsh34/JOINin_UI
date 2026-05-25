import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final SessionService _sessions = SessionService();
  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _activities = ['football', 'cricket', 'badminton', 'basketball', 'tennis', 'pickleball'];
  String? _selectedActivity;
  final _titleController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _slots = 10;
  int _minPlayers = 5;
  String _skillLevel = 'All Welcome';

  @override
  void dispose() {
    _titleController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publishSession() async {
    final activity = _selectedActivity;
    final title = _titleController.text.trim();
    if (activity == null || title.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('Please fill out activity, title, date, and time.'),
      ));
      return;
    }
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    setState(() => _isLoading = true);
    try {
      await _sessions.create({
        'title': title,
        'activityType': activity,
        'venue': {
          'name': _venueNameController.text.trim().isEmpty ? 'TBD' : _venueNameController.text.trim(),
          'address': _venueAddressController.text.trim(),
          'coordinates': {'type': 'Point', 'coordinates': [0, 0]},
        },
        'dateTime': dt.toUtc().toIso8601String(),
        'totalSlots': _slots,
        'minPlayers': _minPlayers,
        'skillLevel': _skillLevel == 'All Welcome' ? 'Beginner' : _skillLevel,
        'description': _descriptionController.text.trim(),
        'isPublic': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.primaryAccent,
        content: Text('Session published!', style: TextStyle(color: AppTheme.darkBackground)),
      ));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(e.toString()),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Session')),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: AppTheme.cardDark,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
            minHeight: 6,
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 4) {
                  setState(() => _currentStep++);
                } else {
                  _publishSession();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          child: _isLoading && _currentStep == 4
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.darkBackground))
                              : Text(_currentStep == 4 ? 'Publish Session' : 'Continue'),
                        ),
                      ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              side: const BorderSide(color: AppTheme.textMuted),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isLoading ? null : details.onStepCancel,
                            child: const Text('Back', style: TextStyle(color: AppTheme.textLight, fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Activity & Title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _activities
                              .map((act) => ChoiceChip(
                                    label: Text(act[0].toUpperCase() + act.substring(1)),
                                    selected: _selectedActivity == act,
                                    selectedColor: AppTheme.primaryAccent,
                                    labelStyle: TextStyle(color: _selectedActivity == act ? AppTheme.darkBackground : AppTheme.textLight, fontWeight: FontWeight.bold),
                                    backgroundColor: AppTheme.cardDark,
                                    onSelected: (_) => setState(() => _selectedActivity = act),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Session title',
                            filled: true,
                            fillColor: AppTheme.cardDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _venueNameController,
                          decoration: InputDecoration(
                            labelText: 'Venue name',
                            filled: true,
                            fillColor: AppTheme.cardDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _venueAddressController,
                          decoration: InputDecoration(
                            labelText: 'Address (optional)',
                            filled: true,
                            fillColor: AppTheme.cardDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Date & Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 60)),
                              );
                              if (d != null) setState(() => _selectedDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_today, color: AppTheme.primaryAccent),
                                  const SizedBox(height: 8),
                                  Text(_selectedDate == null ? 'Select date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                              if (t != null) setState(() => _selectedTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                children: [
                                  const Icon(Icons.access_time, color: AppTheme.secondaryAccent),
                                  const SizedBox(height: 8),
                                  Text(_selectedTime == null ? 'Select time' : _selectedTime!.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Players & Rules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        _buildStepperRow('Total Slots', _slots, (val) => setState(() => _slots = val), min: 2, max: 50),
                        const SizedBox(height: 16),
                        _buildStepperRow('Min Players', _minPlayers, (val) => setState(() => _minPlayers = val), min: 2, max: _slots),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          initialValue: _skillLevel,
                          decoration: InputDecoration(filled: true, fillColor: AppTheme.cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                          items: const ['Beginner', 'Intermediate', 'Advanced', 'All Welcome']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _skillLevel = val ?? 'All Welcome'),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Tell people what to expect',
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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

  Widget _buildStepperRow(String label, int value, void Function(int) onChanged, {required int min, required int max}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.textMuted), onPressed: value > min ? () => onChanged(value - 1) : null),
              SizedBox(width: 30, child: Center(child: Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
              IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent), onPressed: value < max ? () => onChanged(value + 1) : null),
            ],
          )
        ],
      ),
    );
  }
}
