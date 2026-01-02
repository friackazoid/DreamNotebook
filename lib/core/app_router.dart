import 'package:flutter/material.dart';

import '../pages/home_shell_page.dart';

enum AppSection { daily, weekly, monthly, collections, drawing }

class AppRoutePath {
  const AppRoutePath(this.section);

  final AppSection section;
}

class AppRouteParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final location = routeInformation.location ?? '/daily';
    switch (location) {
      case '/weekly':
        return const AppRoutePath(AppSection.weekly);
      case '/monthly':
        return const AppRoutePath(AppSection.monthly);
      case '/collections':
        return const AppRoutePath(AppSection.collections);
      case '/drawing':
        return const AppRoutePath(AppSection.drawing);
      case '/daily':
      default:
        return const AppRoutePath(AppSection.daily);
    }
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    final location = switch (configuration.section) {
      AppSection.weekly => '/weekly',
      AppSection.monthly => '/monthly',
      AppSection.collections => '/collections',
      AppSection.drawing => '/drawing',
      AppSection.daily => '/daily',
    };
    return RouteInformation(location: location);
  }
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  AppSection _section = AppSection.daily;

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void setSection(AppSection section) {
    if (_section == section) return;
    _section = section;
    notifyListeners();
  }

  @override
  AppRoutePath get currentConfiguration => AppRoutePath(_section);

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _section = configuration.section;
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
