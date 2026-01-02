import 'package:flutter/material.dart';

import '../widgets/weekly_planner_spread.dart';

class WeeklyPlannerPage extends StatelessWidget {
  const WeeklyPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: WeeklyPlannerSpread(),
      ),
    );
  }
}
