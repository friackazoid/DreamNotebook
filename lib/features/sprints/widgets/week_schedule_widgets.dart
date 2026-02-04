import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/sprint_week_plan.dart';

class WeekSchedulePageBase extends StatelessWidget {
  const WeekSchedulePageBase({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class TaskTableSection extends StatelessWidget {
  const TaskTableSection({
    super.key,
    required this.title,
    required this.rows,
    required this.isEditable,
    required this.onChanged,
  });

  final String title;
  final List<WeeklyTaskRow> rows;
  final bool isEditable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1),
            7: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: theme.dividerColor),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                _headerCell(context, ''),
                ..._dayLabels.map((label) => _headerCell(context, label)).toList(),
              ],
            ),
            ...rows.map((row) => _taskRow(context, row)),
          ],
        ),
      ],
    );
  }

  TableRow _taskRow(BuildContext context, WeeklyTaskRow row) {
    return TableRow(
      children: [
        _taskCell(context, row),
        ...List.generate(7, (index) => _dayCell(context, row, index)),
      ],
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.hintColor,
        ),
      ),
    );
  }

  Widget _taskCell(BuildContext context, WeeklyTaskRow row) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: row.done,
            onChanged: isEditable
                ? (value) {
                    row.done = value ?? false;
                    onChanged();
                  }
                : null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextFormField(
              initialValue: row.text,
              enabled: isEditable,
              maxLines: 1,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (value) {
                row.text = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, WeeklyTaskRow row, int index) {
    final theme = Theme.of(context);
    final value = row.dayMarks[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        initialValue: value == 0 ? '' : _formatNumber(value),
        enabled: isEditable,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        style: theme.textTheme.bodySmall,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
        ),
        onChanged: (raw) {
          row.dayMarks[index] = double.tryParse(raw) ?? 0.0;
          onChanged();
        },
      ),
    );
  }
}

class StateTrackerSection extends StatelessWidget {
  const StateTrackerSection({
    super.key,
    required this.stateTracker,
    required this.isEditable,
    required this.onChanged,
  });

  final StateTracker stateTracker;
  final bool isEditable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATE TRACKER',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.6),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1),
            7: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: theme.dividerColor),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                _headerCell(context, ''),
                ..._dayLabels.map((label) => _headerCell(context, label)).toList(),
              ],
            ),
            ...SprintZone.values.map(
              (zone) => _zoneRow(context, zone),
            ),
          ],
        ),
      ],
    );
  }

  TableRow _zoneRow(BuildContext context, SprintZone zone) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            _zoneLabels[zone] ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ...List.generate(7, (dayIndex) => _zoneCell(zone, dayIndex)),
      ],
    );
  }

  Widget _zoneCell(SprintZone zone, int dayIndex) {
    final selected = stateTracker.selectedZoneByDay[dayIndex];
    return Center(
      child: Radio<SprintZone>(
        value: zone,
        groupValue: selected,
        onChanged: isEditable
            ? (value) {
                stateTracker.selectedZoneByDay[dayIndex] = value;
                onChanged();
              }
            : null,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.hintColor,
        ),
      ),
    );
  }
}

const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const Map<SprintZone, String> _zoneLabels = {
  SprintZone.red: 'Red zone (uncontrolled panic)',
  SprintZone.orange: 'Orange zone (overstimulation, anxiety)',
  SprintZone.yellow: 'Yellow zone (engagement, interest)',
  SprintZone.green: 'Green zone (balance, stability)',
  SprintZone.turquoise: 'Turquoise zone (relaxation, calm)',
  SprintZone.blue: 'Blue zone (passivity, detachment)',
  SprintZone.purple: 'Purple zone (apathy, numbness)',
};

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
