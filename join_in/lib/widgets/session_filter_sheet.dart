import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/session_filters.dart';
import '../theme.dart';

/// Bottom sheet that lets the user edit [SessionFilters] for the home feed.
///
/// Returns the new filters when the user taps "Apply", or `null` when the
/// sheet is dismissed without applying. The activity chip and sort live on
/// this sheet too so everything filter-related is in one place.
class SessionFilterSheet extends StatefulWidget {
  const SessionFilterSheet({
    super.key,
    required this.initial,
  });

  final SessionFilters initial;

  static Future<SessionFilters?> show(
    BuildContext context, {
    required SessionFilters initial,
  }) {
    return showModalBottomSheet<SessionFilters>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SessionFilterSheet(initial: initial),
    );
  }

  @override
  State<SessionFilterSheet> createState() => _SessionFilterSheetState();
}

class _SessionFilterSheetState extends State<SessionFilterSheet> {
  late SessionFilters _draft;

  static const _skillLevels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = (_draft.dateFrom != null && _draft.dateTo != null)
        ? DateTimeRange(start: _draft.dateFrom!, end: _draft.dateTo!)
        : DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 7)),
          );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      initialDateRange: initial,
      helpText: 'Show sessions between',
      saveText: 'Set',
    );
    if (range != null) {
      setState(() {
        _draft = _draft.copyWith(
          dateFrom: DateTime(range.start.year, range.start.month,
              range.start.day, 0, 0, 0),
          dateTo: DateTime(
              range.end.year, range.end.month, range.end.day, 23, 59, 59),
        );
      });
    }
  }

  void _clearDateRange() {
    HapticFeedback.selectionClick();
    setState(() {
      _draft = _draft.copyWith(dateFrom: null, dateTo: null);
    });
  }

  void _clearAll() {
    HapticFeedback.selectionClick();
    setState(() {
      // Keep activity & sort, blow away advanced filters only.
      _draft = SessionFilters(
        activityType: _draft.activityType,
        sort: _draft.sort,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = (_draft.dateFrom != null && _draft.dateTo != null)
        ? '${DateFormat('MMM d').format(_draft.dateFrom!)} – ${DateFormat('MMM d').format(_draft.dateTo!)}'
        : 'Any time';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (_draft.hasAnyAdvanced)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    _SectionTitle('Date range'),
                    _PickerRow(
                      icon: Icons.event,
                      label: dateLabel,
                      trailing: (_draft.dateFrom != null)
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  size: 18, color: context.cs.onSurfaceVariant),
                              onPressed: _clearDateRange,
                            )
                          : null,
                      onTap: _pickDateRange,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('Skill level'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ToggleChip(
                          label: 'Any',
                          selected: _draft.skillLevel == null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _draft =
                                _draft.copyWith(skillLevel: null));
                          },
                        ),
                        for (final level in _skillLevels)
                          _ToggleChip(
                            label: level,
                            selected: _draft.skillLevel == level,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _draft =
                                  _draft.copyWith(skillLevel: level));
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('Availability'),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Only sessions with open slots',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Hides sessions that are already full',
                          style: TextStyle(
                              color: context.cs.onSurfaceVariant,
                              fontSize: 12)),
                      value: _draft.slotsAvailable ?? false,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _draft = _draft.copyWith(
                            slotsAvailable: val ? true : null));
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('Sort by'),
                    RadioGroup<SessionSort>(
                      groupValue: _draft.sort,
                      onChanged: (val) {
                        if (val == null) return;
                        HapticFeedback.selectionClick();
                        setState(
                            () => _draft = _draft.copyWith(sort: val));
                      },
                      child: Column(
                        children: SessionSort.values.map((sort) {
                          final selected = _draft.sort == sort;
                          return RadioListTile<SessionSort>(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppTheme.primaryAccent,
                            title: Text(sort.label,
                                style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                            value: sort,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context, _draft);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: TextStyle(
              color: context.cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: 12)),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right,
                    color: context.cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : context.cs.surfaceContainerLow,
          border: Border.all(
              color: selected ? Colors.transparent : context.cs.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? AppTheme.darkBackground
                    : context.cs.onSurface)),
      ),
    );
  }
}
