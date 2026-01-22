import 'package:flutter/material.dart';

import '../core/app_router.dart';
import '../features/collections/pages/collections_page.dart';
import '../features/planner/pages/daily_planner_page.dart';
import '../features/planner/pages/monthly_planner_page.dart';
import '../features/planner/pages/weekly_planner_page.dart';
import '../features/sprints/pages/sprint_projects_tab.dart';
import 'quick_note_tab_page.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({
    super.key,
    required this.section,
    required this.onSectionSelected,
    this.dailyDate,
    this.weeklyDate,
    this.monthlyDate,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSectionSelected;
  final DateTime? dailyDate;
  final DateTime? weeklyDate;
  final DateTime? monthlyDate;

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
              NavigationRail(
                extended: isWide,
                selectedIndex: _sectionIndex(section),
                onDestinationSelected: (index) =>
                    onSectionSelected(_sectionFromIndex(index)),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.today_outlined),
                    selectedIcon: Icon(Icons.today),
                    label: Text('Daily'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.view_week_outlined),
                    selectedIcon: Icon(Icons.view_week),
                    label: Text('Weekly'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: Text('Monthly'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.flag_outlined),
                    selectedIcon: Icon(Icons.flag),
                    label: Text('Sprints Projects'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.collections_bookmark_outlined),
                    selectedIcon: Icon(Icons.collections_bookmark),
                    label: Text('Collections'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sticky_note_2_outlined),
                    selectedIcon: Icon(Icons.sticky_note_2),
                    label: Text('Quick Note'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _sectionContent(section)),
            ],
          );
        },
      ),
    );
  }

  int _sectionIndex(AppSection section) {
    return switch (section) {
      AppSection.daily => 0,
      AppSection.weekly => 1,
      AppSection.monthly => 2,
      AppSection.sprints => 3,
      AppSection.collections => 4,
      AppSection.quickNote => 5,
    };
  }

  AppSection _sectionFromIndex(int index) {
    return switch (index) {
      1 => AppSection.weekly,
      2 => AppSection.monthly,
      3 => AppSection.sprints,
      4 => AppSection.collections,
      5 => AppSection.quickNote,
      _ => AppSection.daily,
    };
  }

  Widget _sectionContent(AppSection section) {
    return switch (section) {
      AppSection.daily => DailyPlannerPage(initialDate: dailyDate),
      AppSection.weekly => WeeklyPlannerPage(initialDate: weeklyDate),
      AppSection.monthly => MonthlyPlannerPage(initialDate: monthlyDate),
      AppSection.sprints => const SprintProjectsTab(),
      AppSection.collections => const CollectionsPage(),
      AppSection.quickNote => const QuickNoteTabPage(),
    };
  }
}
