import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';
import 'dotted_background.dart';
import 'handwriting_canvas.dart';

class QuickNotePanel extends StatefulWidget {
  const QuickNotePanel({
    super.key,
    required this.initialStrokes,
  });

  final List<Stroke> initialStrokes;

  @override
  State<QuickNotePanel> createState() => _QuickNotePanelState();
}

class _QuickNotePanelState extends State<QuickNotePanel> {
  late final HandwritingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HandwritingController();
    _controller.loadStrokes(widget.initialStrokes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _close();
        return false;
      },
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Quick Note',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _close,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final isErasing =
                      _controller.tool == HandwritingTool.eraser;
                  return Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _controller.setTool(HandwritingTool.pen),
                        icon: Icon(
                          Icons.edit,
                          color: isErasing
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.primary,
                        ),
                        label: const Text('Pen'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _controller.setTool(HandwritingTool.eraser),
                        icon: Icon(
                          Icons.auto_fix_high,
                          color: isErasing
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        label: const Text('Eraser'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear'),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DottedBackground(
                      child: HandwritingCanvas(controller: _controller),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_controller.strokes);
  }
}

Future<List<Stroke>?> showQuickNotePanel(
  BuildContext context, {
  required List<Stroke> initialStrokes,
}) {
  return showModalBottomSheet<List<Stroke>>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    useSafeArea: true,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: QuickNotePanel(initialStrokes: initialStrokes),
      );
    },
  );
}
