import 'package:flutter/material.dart';

class WeeklyLoadBar extends StatelessWidget {
  const WeeklyLoadBar({
    super.key,
    required this.dailyLoads,
    required this.labels,
  });

  final List<double> dailyLoads;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = dailyLoads.fold<double>(0, (sum, value) => sum + value);
    const totalHours = 24 * 7;
    const sleepHours = 10 * 7; // Sleep is fixed at 20:00–06:00.
    final free = (totalHours - sleepHours - busy).clamp(0, totalHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoadStackBar(
          busy: busy,
          sleep: sleepHours.toDouble(),
          free: free.toDouble(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendItem(
              label: 'Busy',
              value: busy,
              color: const Color(0xFFFF6163),
            ),
            _LegendItem(
              label: 'Sleep 20-06',
              value: sleepHours.toDouble(),
              color: const Color(0xFF000084),
            ),
            _LegendItem(
              label: 'Free',
              value: free.toDouble(),
              color: const Color(0xFF00B036),
            ),
            Text(
              'Total ${_formatNumber(totalHours.toDouble())}h',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Column(
                children: [
                  Text(
                    labels[index],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatNumber(dailyLoads[index]),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LoadStackBar extends StatelessWidget {
  const _LoadStackBar({
    required this.busy,
    required this.sleep,
    required this.free,
  });

  final double busy;
  final double sleep;
  final double free;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final total = busy + free + sleep;
          final safeTotal = total == 0 ? 1 : total;
          final busyWidth = width * (busy / safeTotal);
          final sleepWidth = width * (sleep / safeTotal);
          final freeWidth = width * (free / safeTotal);
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: busyWidth,
                    height: double.infinity,
                    child: const ColoredBox(color: Color(0xFFFF6163)),
                  ),
                  SizedBox(
                    width: sleepWidth,
                    height: double.infinity,
                    child: const ColoredBox(color: Color(0xFF000084)),
                  ),
                  SizedBox(
                    width: freeWidth,
                    height: double.infinity,
                    child: const ColoredBox(color: Color(0xFF00B036)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${_formatNumber(value)}h',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ],
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
