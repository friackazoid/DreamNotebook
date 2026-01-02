import 'package:flutter/material.dart';

class UrgentImportantMatrix extends StatelessWidget {
  const UrgentImportantMatrix({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final Map<String, String> values;
  final void Function(String key, String value) onChanged;

  static const urgentImportantKey = 'urgentImportant';
  static const urgentNotImportantKey = 'urgentNotImportant';
  static const notUrgentImportantKey = 'notUrgentImportant';
  static const notUrgentNotImportantKey = 'notUrgentNotImportant';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgent / Important Matrix',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MatrixCell(
                  width: cellWidth,
                  title: 'Urgent & Important',
                  value: values[urgentImportantKey] ?? '',
                  onChanged: (text) =>
                      onChanged(urgentImportantKey, text),
                ),
                _MatrixCell(
                  width: cellWidth,
                  title: 'Urgent, Not Important',
                  value: values[urgentNotImportantKey] ?? '',
                  onChanged: (text) =>
                      onChanged(urgentNotImportantKey, text),
                ),
                _MatrixCell(
                  width: cellWidth,
                  title: 'Not Urgent, Important',
                  value: values[notUrgentImportantKey] ?? '',
                  onChanged: (text) =>
                      onChanged(notUrgentImportantKey, text),
                ),
                _MatrixCell(
                  width: cellWidth,
                  title: 'Not Urgent or Important',
                  value: values[notUrgentNotImportantKey] ?? '',
                  onChanged: (text) =>
                      onChanged(notUrgentNotImportantKey, text),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MatrixCell extends StatefulWidget {
  const _MatrixCell({
    required this.width,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final double width;
  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_MatrixCell> createState() => _MatrixCellState();
}

class _MatrixCellState extends State<_MatrixCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _MatrixCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                onChanged: widget.onChanged,
                decoration: const InputDecoration(
                  hintText: 'List priorities',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
