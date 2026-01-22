import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/sprint.dart';

class SprintTableLayout extends StatelessWidget {
  const SprintTableLayout({
    super.key,
    required this.sprint,
    required this.isEditable,
    required this.onChanged,
  });

  final Sprint sprint;
  final bool isEditable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final sections = sprint.sections
            .map(
              (section) => _SprintSectionTable(
                section: section,
                isEditable: isEditable,
                onChanged: onChanged,
              ),
            )
            .toList();
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _withGutters(
                  sections
                      .map((section) => Expanded(child: section))
                      .toList(),
                ),
              )
            : Column(
                children: _withGutters(sections, isVertical: true),
              );
      },
    );
  }
}

List<Widget> _withGutters(
  List<Widget> children, {
  bool isVertical = false,
}) {
  if (children.isEmpty) return [];
  final spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    spaced.add(children[i]);
    if (i != children.length - 1) {
      spaced.add(SizedBox(height: isVertical ? 16 : 0, width: isVertical ? 0 : 16));
    }
  }
  return spaced;
}

class _SprintSectionTable extends StatelessWidget {
  const _SprintSectionTable({
    required this.section,
    required this.isEditable,
    required this.onChanged,
  });

  final SprintSection section;
  final bool isEditable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekTotals = List<double>.filled(4, 0);
    var total = 0.0;
    for (final item in section.items) {
      for (var weekIndex = 0; weekIndex < 4; weekIndex++) {
        final value = item.weekValues[weekIndex];
        weekTotals[weekIndex] += value;
        total += value;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: theme.dividerColor),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                _headerCell(context, ''),
                _headerCell(context, 'Week 1'),
                _headerCell(context, 'Week 2'),
                _headerCell(context, 'Week 3'),
                _headerCell(context, 'Week 4'),
              ],
            ),
            ...section.items.map(
              (item) => TableRow(
                children: [
                  _taskCell(context, item),
                  ...List.generate(
                    4,
                    (weekIndex) => _weekValueCell(
                      context,
                      item,
                      weekIndex,
                    ),
                  ),
                ],
              ),
            ),
            TableRow(
              children: [
                _totalLabelCell(context, total),
                ...List.generate(
                  4,
                  (index) => _totalValueCell(context, weekTotals[index]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
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

  Widget _taskCell(BuildContext context, SprintItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: item.done,
            onChanged: isEditable
                ? (value) {
                    item.done = value ?? false;
                    onChanged();
                  }
                : null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextFormField(
              initialValue: item.text,
              enabled: isEditable,
              maxLines: 1,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (value) {
                item.text = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekValueCell(BuildContext context, SprintItem item, int weekIndex) {
    final theme = Theme.of(context);
    final value = item.weekValues[weekIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextFormField(
        initialValue: value == 0 ? '' : _formatNumber(value),
        enabled: isEditable,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
        ),
        onChanged: (raw) {
          final parsed = double.tryParse(raw) ?? 0;
          item.weekValues[weekIndex] = parsed;
          onChanged();
        },
      ),
    );
  }

  Widget _totalLabelCell(BuildContext context, double total) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        'Total (hours): ${_formatNumber(total)}',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _totalValueCell(BuildContext context, double value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        _formatNumber(value),
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
