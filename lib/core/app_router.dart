import 'package:flutter/material.dart';

import '../pages/home_shell_page.dart';

enum AppSection { daily, weekly, monthly, sprints, collections, quickNote }

class AppRoutePath {
  const AppRoutePath(
    this.section, {
    this.dailyDate,
    this.weekStart,
    this.month,
    this.sprintWeekIndex,
  });

  final AppSection section;
  final DateTime? dailyDate;
  final DateTime? weekStart;
  final DateTime? month;
  final int? sprintWeekIndex;
}

class AppRouteParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location ?? '/daily');
    switch (uri.path) {
      case '/weekly':
        return AppRoutePath(
          AppSection.weekly,
          weekStart: _parseDateKey(uri.queryParameters['start']),
        );
      case '/monthly':
        return AppRoutePath(
          AppSection.monthly,
          month: _parseMonthKey(uri.queryParameters['month']),
        );
      case '/quick-note':
        return const AppRoutePath(AppSection.quickNote);
      case '/sprints':
        return AppRoutePath(
          AppSection.sprints,
          sprintWeekIndex: _parseSprintWeek(uri.queryParameters['week']),
        );
      case '/collections':
        return const AppRoutePath(AppSection.collections);
      case '/daily':
      default:
        return AppRoutePath(
          AppSection.daily,
          dailyDate: _parseDateKey(uri.queryParameters['date']),
        );
    }
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    final location = switch (configuration.section) {
      AppSection.weekly => _weeklyLocation(configuration.weekStart),
      AppSection.monthly => _monthlyLocation(configuration.month),
      AppSection.sprints => _sprintsLocation(configuration.sprintWeekIndex),
      AppSection.collections => '/collections',
      AppSection.quickNote => '/quick-note',
      AppSection.daily => _dailyLocation(configuration.dailyDate),
    };
    return RouteInformation(location: location);
  }
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  AppSection _section = AppSection.daily;
  DateTime? _dailyDate;
  DateTime? _weeklyStart;
  DateTime? _monthlyStart;
  int? _sprintWeekIndex;

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void setSection(AppSection section) {
    if (_section == section) return;
    _section = section;
    notifyListeners();
  }

  void routeToDaily(DateTime date) {
    _dailyDate = _normalizeDate(date);
    _section = AppSection.daily;
    notifyListeners();
  }

  void routeToWeekly(DateTime anyDay) {
    _weeklyStart = _startOfWeekMonday(anyDay);
    _section = AppSection.weekly;
    notifyListeners();
  }

  void routeToMonthly(DateTime anyDay) {
    _monthlyStart = DateTime(anyDay.year, anyDay.month, 1);
    _section = AppSection.monthly;
    notifyListeners();
  }

  void routeToSprints({int? weekIndex}) {
    _sprintWeekIndex = weekIndex;
    _section = AppSection.sprints;
    notifyListeners();
  }

  @override
  AppRoutePath get currentConfiguration => AppRoutePath(
        _section,
        dailyDate: _dailyDate,
        weekStart: _weeklyStart,
        month: _monthlyStart,
        sprintWeekIndex: _sprintWeekIndex,
      );

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _section = configuration.section;
    _dailyDate = configuration.dailyDate ?? _dailyDate;
    _weeklyStart = configuration.weekStart ?? _weeklyStart;
    _monthlyStart = configuration.month ?? _monthlyStart;
    _sprintWeekIndex = configuration.sprintWeekIndex ?? _sprintWeekIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          child: HomeShellPage(
            section: _section,
            onSectionSelected: setSection,
            dailyDate: _dailyDate,
            weeklyDate: _weeklyStart,
            monthlyDate: _monthlyStart,
            sprintWeekIndex: _sprintWeekIndex,
            onSprintWeekSelected: routeToSprints,
          ),
        ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        if (_section != AppSection.daily) {
          _section = AppSection.daily;
          notifyListeners();
          return true;
        }
        return false;
      },
    );
  }
}

void routeToDaily(BuildContext context, DateTime date) {
  final delegate = Router.of(context).routerDelegate;
  if (delegate is AppRouterDelegate) {
    delegate.routeToDaily(date);
  }
}

void routeToWeekly(BuildContext context, DateTime anyDay) {
  final delegate = Router.of(context).routerDelegate;
  if (delegate is AppRouterDelegate) {
    delegate.routeToWeekly(anyDay);
  }
}

void routeToMonthly(BuildContext context, DateTime anyDay) {
  final delegate = Router.of(context).routerDelegate;
  if (delegate is AppRouterDelegate) {
    delegate.routeToMonthly(anyDay);
  }
}

void routeToSprints(BuildContext context, {int? weekIndex}) {
  final delegate = Router.of(context).routerDelegate;
  if (delegate is AppRouterDelegate) {
    delegate.routeToSprints(weekIndex: weekIndex);
  }
}

String _dailyLocation(DateTime? date) {
  if (date == null) return '/daily';
  final key = _dateKey(date);
  return '/daily?date=$key';
}

String _weeklyLocation(DateTime? start) {
  if (start == null) return '/weekly';
  final key = _dateKey(_startOfWeekMonday(start));
  return '/weekly?start=$key';
}

String _monthlyLocation(DateTime? month) {
  if (month == null) return '/monthly';
  final key = _monthKey(DateTime(month.year, month.month, 1));
  return '/monthly?month=$key';
}

String _sprintsLocation(int? weekIndex) {
  if (weekIndex == null || weekIndex == 0) return '/sprints';
  return '/sprints?week=$weekIndex';
}

DateTime? _parseDateKey(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

DateTime? _parseMonthKey(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return null;
  return DateTime(year, month, 1);
}

int? _parseSprintWeek(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 1 || parsed > 4) return null;
  return parsed;
}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _startOfWeekMonday(DateTime date) {
  final normalized = _normalizeDate(date);
  final diff = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: diff));
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _monthKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}
