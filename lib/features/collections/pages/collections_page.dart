import 'package:flutter/material.dart';

import '../../../core/state/notebook_state.dart';
import '../../../models/collection_item.dart';
import '../../../models/notebook_data.dart';
import '../../../widgets/section_card.dart';
import '../widgets/pet_project_section.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return ValueListenableBuilder<NotebookData>(
      valueListenable: state,
      builder: (context, data, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Collections',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            CollectionSection(
              title: 'Movies to watch',
              items: data.collections.movies,
              onAdd: (text) =>
                  state.addCollectionItem(CollectionType.movies, text),
              onToggle: (item) => state.toggleCollectionItem(
                CollectionType.movies,
                item.id,
              ),
            ),
            const SizedBox(height: 16),
            CollectionSection(
              title: 'Books to read',
              items: data.collections.books,
              onAdd: (text) =>
                  state.addCollectionItem(CollectionType.books, text),
              onToggle: (item) => state.toggleCollectionItem(
                CollectionType.books,
                item.id,
              ),
            ),
            const SizedBox(height: 16),
            CollectionSection(
              title: 'Games to play',
              items: data.collections.games,
              onAdd: (text) =>
                  state.addCollectionItem(CollectionType.games, text),
              onToggle: (item) => state.toggleCollectionItem(
                CollectionType.games,
                item.id,
              ),
            ),
            const SizedBox(height: 16),
            PetProjectSection(
              tasks: data.petProject.tasks,
              notes: data.petProject.notes,
              onAddTask: (title, dueDate) =>
                  state.addPetTask(title, dueDate),
              onToggleTask: (task) => state.togglePetTask(task.id),
              onNotesChanged: state.updatePetNotes,
            ),
          ],
        );
      },
    );
  }
}

class CollectionSection extends StatefulWidget {
  const CollectionSection({
    super.key,
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onToggle,
  });

  final String title;
  final List<CollectionItem> items;
  final ValueChanged<String> onAdd;
  final ValueChanged<CollectionItem> onToggle;

  @override
  State<CollectionSection> createState() => _CollectionSectionState();
}

class _CollectionSectionState extends State<CollectionSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: widget.title,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add an item',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            Text(
              'No entries yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...widget.items.map(
              (item) => CheckboxListTile(
                value: item.isDone,
                onChanged: (_) => widget.onToggle(item),
                title: Text(item.title),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}
