import 'package:flutter/material.dart';

import '../core/app_router.dart';
import '../features/collections/pages/collections_page.dart';
import '../features/planner/pages/daily_planner_page.dart';
import '../features/planner/pages/monthly_planner_page.dart';
import '../features/sprints/pages/sprint_projects_tab.dart';
import 'quick_note_tab_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    required this.section,
    required this.onSectionSelected,
    this.dailyDate,
    this.monthlyDate,
    this.sprintWeekIndex,
    required this.onSprintWeekSelected,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSectionSelected;
  final DateTime? dailyDate;
  final DateTime? monthlyDate;
  final int? sprintWeekIndex;
  final void Function({int? weekIndex}) onSprintWeekSelected;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  bool _sprintsExpanded = false;

  @override
  void initState() {
    super.initState();
    _sprintsExpanded = widget.section == AppSection.sprints &&
        (widget.sprintWeekIndex ?? 0) > 0;
  }

  @override
  void didUpdateWidget(covariant HomeShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != oldWidget.section &&
        widget.section != AppSection.sprints) {
      return;
    }
    if (widget.section == AppSection.sprints &&
        (widget.sprintWeekIndex ?? 0) > 0) {
      _sprintsExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Row(
            children: [
              SizedBox(
                width: isWide ? 260 : 220,
                child: _buildSidebar(context),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _sectionContent(widget.section)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSection = widget.section;
    final sprintWeekIndex = widget.sprintWeekIndex ?? 0;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _NavItem(
          label: 'Daily',
          icon: Icons.today_outlined,
          selected: selectedSection == AppSection.daily,
          onTap: () => widget.onSectionSelected(AppSection.daily),
        ),
        _NavItem(
          label: 'Monthly',
          icon: Icons.calendar_month_outlined,
          selected: selectedSection == AppSection.monthly,
          onTap: () => widget.onSectionSelected(AppSection.monthly),
        ),
        ListTile(
          selected:
              selectedSection == AppSection.sprints && sprintWeekIndex == 0,
          leading: Icon(
            Icons.flag_outlined,
            color: selectedSection == AppSection.sprints
                ? theme.colorScheme.primary
                : null,
          ),
          title: Text(
            'Sprint Project',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: selectedSection == AppSection.sprints
                  ? theme.colorScheme.primary
                  : null,
            ),
          ),
          trailing: Icon(
            _sprintsExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () {
            setState(() => _sprintsExpanded = !_sprintsExpanded);
            widget.onSprintWeekSelected(weekIndex: 0);
          },
        ),
        if (_sprintsExpanded) ...[
          _SubNavItem(
            label: 'Sprint Overview',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 0,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 0),
          ),
          _SubNavItem(
            label: 'Week 1',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 1,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 1),
          ),
          _SubNavItem(
            label: 'Results Week 1',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 2,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 2),
          ),
          _SubNavItem(
            label: 'Week 2',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 3,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 3),
          ),
          _SubNavItem(
            label: 'Results Week 2',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 4,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 4),
          ),
          _SubNavItem(
            label: 'Week 3',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 5,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 5),
          ),
          _SubNavItem(
            label: 'Results Week 3',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 6,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 6),
          ),
          _SubNavItem(
            label: 'Integration Week',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 7,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 7),
          ),
          _SubNavItem(
            label: 'Results Integration Week',
            selected:
                selectedSection == AppSection.sprints && sprintWeekIndex == 8,
            onTap: () => widget.onSprintWeekSelected(weekIndex: 8),
          ),
        ],
        _NavItem(
          label: 'Collections',
          icon: Icons.collections_bookmark_outlined,
          selected: selectedSection == AppSection.collections,
          onTap: () => widget.onSectionSelected(AppSection.collections),
        ),
        _NavItem(
          label: 'Quick Note',
          icon: Icons.sticky_note_2_outlined,
          selected: selectedSection == AppSection.quickNote,
          onTap: () => widget.onSectionSelected(AppSection.quickNote),
        ),
      ],
    );
  }

  Widget _sectionContent(AppSection section) {
    return switch (section) {
      AppSection.daily => DailyPlannerPage(initialDate: widget.dailyDate),
      AppSection.monthly => MonthlyPlannerPage(initialDate: widget.monthlyDate),
      AppSection.sprints => SprintProjectsTab(
          weekIndex: widget.sprintWeekIndex ?? 0,
        ),
      AppSection.collections => const CollectionsPage(),
      AppSection.quickNote => const QuickNoteTabPage(),
    };
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      selected: selected,
      leading: Icon(
        icon,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SubNavItem extends StatelessWidget {
  const _SubNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      selected: selected,
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      title: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      onTap: onTap,
    );
  }
}
