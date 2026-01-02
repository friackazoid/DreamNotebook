import 'package:flutter/material.dart';

import '../widgets/handwriting_canvas.dart';
import '../widgets/notebook_background.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late final DrawingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DrawingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isErasing = _controller.isErasing;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () =>
                    setState(() => _controller.setEraser(false)),
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
                    setState(() => _controller.setEraser(true)),
                icon: Icon(
                  Icons.auto_fix_high,
                  color: isErasing
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: const Text('Eraser'),
              ),
              const SizedBox(width: 24),
              Text('Stroke', style: Theme.of(context).textTheme.labelLarge),
              Expanded(
                child: Slider(
                  value: _controller.strokeWidth,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _controller.strokeWidth.toStringAsFixed(0),
                  onChanged: (value) =>
                      setState(() => _controller.setStrokeWidth(value)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(_controller.clear),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Page'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: NotebookBackground(
                  child: HandwritingCanvas(controller: _controller),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
