import 'package:flutter/material.dart';
import '../theme.dart';
import '../dummy_data.dart'; // Just for dummy structures if needed
import 'dart:ui';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _activities = ['Football', 'Cricket', 'Badminton', 'Basketball', 'Tennis', 'Pickleball'];
  String? _selectedActivity;
  final _venueController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _slots = 10;
  int _minPlayers = 5;
  String _skillLevel = 'All Welcome';
  
  void _publishSession() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session Published!'), backgroundColor: AppTheme.primaryAccent));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Session')),
      body: Column(
        children: [
          // Progress Bar
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
                if (_currentStep < 4) setState(() => _currentStep++);
                else _publishSession();
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
                  title: const Text('Activity Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: const Text('What sport are you playing?', style: TextStyle(color: AppTheme.textMuted)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 12, runSpacing: 12,
                      children: _activities.map((act) => ChoiceChip(
                        label: Text(act),
                        selected: _selectedActivity == act,
                        selectedColor: AppTheme.primaryAccent,
                        labelStyle: TextStyle(color: _selectedActivity == act ? AppTheme.darkBackground : AppTheme.textLight, fontWeight: FontWeight.bold),
                        backgroundColor: AppTheme.cardDark,
                        onSelected: (val) => setState(() => _selectedActivity = act),
                      )).toList(),
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Where is it happening?', style: TextStyle(color: AppTheme.textMuted)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _venueController,
                          onChanged: (val) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Search Venue',
                            filled: true, fillColor: AppTheme.cardDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAccent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 180, width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16),
                            image: _venueController.text.isNotEmpty ? const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop'), fit: BoxFit.cover) : null,
                          ),
                          child: Center(
                            child: Icon(Icons.location_on, size: 48, color: _venueController.text.isNotEmpty ? AppTheme.primaryAccent : AppTheme.textMuted),
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
                  subtitle: const Text('When should people arrive?', style: TextStyle(color: AppTheme.textMuted)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                              if (d != null) setState(() => _selectedDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_today, color: AppTheme.primaryAccent),
                                  const SizedBox(height: 8),
                                  Text(_selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  subtitle: const Text('Set the capacity and skill level', style: TextStyle(color: AppTheme.textMuted)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        _buildStepperRow('Total Slots', _slots, (val) => setState(() => _slots = val), min: 2, max: 50),
                        const SizedBox(height: 16),
                        _buildStepperRow('Min Players', _minPlayers, (val) => setState(() => _minPlayers = val), min: 2, max: _slots),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _skillLevel,
                          decoration: InputDecoration(filled: true, fillColor: AppTheme.cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                          items: ['Beginner', 'Intermediate', 'Advanced', 'All Welcome'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => _skillLevel = val!),
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Preview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: const Text('This is how others will see it', style: TextStyle(color: AppTheme.textMuted)),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      decoration: BoxDecoration(color: AppTheme.cardDarkElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.primaryAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text(_selectedActivity ?? 'Activity', style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                                  child: Text(_skillLevel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Casual $_selectedActivity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Expanded(child: Text(_venueController.text.isEmpty ? 'Venue Name' : _venueController.text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('${_selectedDate?.day ?? 'DD'}/${_selectedDate?.month ?? 'MM'} at ${_selectedTime?.format(context) ?? 'Time'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const CircleAvatar(radius: 12, backgroundColor: AppTheme.primaryAccent),
                                const SizedBox(width: 8),
                                const Text('You', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text('1/$_slots joined', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildStepperRow(String label, int value, Function(int) onChanged, {required int min, required int max}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.textMuted), onPressed: () => value > min ? onChanged(value - 1) : null),
              SizedBox(width: 30, child: Center(child: Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
              IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent), onPressed: () => value < max ? onChanged(value + 1) : null),
            ],
          )
        ],
      ),
    );
  }
}
