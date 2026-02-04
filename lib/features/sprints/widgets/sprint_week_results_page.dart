import 'package:flutter/material.dart';

import '../../../models/sprint_week_results.dart';

class SprintWeekResultsPage extends StatelessWidget {
  const SprintWeekResultsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.results,
    required this.isEditable,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final SprintWeekResults results;
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
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
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
        _ResultsBlock(
          title: 'WHAT WAS DONE?',
          section: results.done,
          isEditable: isEditable,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        _ResultsBlock(
          title: 'WHAT WAS NOT DONE?',
          section: results.notDone,
          isEditable: isEditable,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        _ResultsBlock(
          title: 'HOW SHOULD THE PLAN BE ADJUSTED?',
          section: results.adjustPlan,
          isEditable: isEditable,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultsBlock extends StatelessWidget {
  const _ResultsBlock({
    required this.title,
    required this.section,
    required this.isEditable,
    required this.onChanged,
  });

  final String title;
  final ResultsSection section;
  final bool isEditable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _LinedEntryField(
          label: 'Foundation',
          text: section.foundationText,
          isEditable: isEditable,
          onChanged: (value) {
            section.foundationText = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _LinedEntryField(
          label: 'Drive',
          text: section.driveText,
          isEditable: isEditable,
          onChanged: (value) {
            section.driveText = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _LinedEntryField(
          label: 'Joy',
          text: section.joyText,
          isEditable: isEditable,
          onChanged: (value) {
            section.joyText = value;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _LinedEntryField extends StatefulWidget {
  const _LinedEntryField({
    required this.label,
    required this.text,
    required this.isEditable,
    required this.onChanged,
  });

  final String label;
  final String text;
  final bool isEditable;
  final ValueChanged<String> onChanged;

  @override
  State<_LinedEntryField> createState() => _LinedEntryFieldState();
}

class _LinedEntryFieldState extends State<_LinedEntryField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant _LinedEntryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text &&
        _controller.text != widget.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 96,
          child: CustomPaint(
            painter: _LinedPaperPainter(
              color: theme.dividerColor.withOpacity(0.6),
            ),
            child: TextField(
              controller: _controller,
              enabled: widget.isEditable,
              maxLines: null,
              expands: true,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  _LinedPaperPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const lineHeight = 20.0;
    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPaperPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
