import 'package:flutter/material.dart';

import '../widgets/monthly_planner_spread.dart';

class MonthlyPlannerPage extends StatelessWidget {
  const MonthlyPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: MonthlyPlannerSpread(),
      ),
    );
  }
}
