import 'package:flutter/material.dart';

import 'core/app_router.dart';
import 'core/state/notebook_state.dart';
import 'core/storage/storage_service.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  final state = NotebookState(storage);
  await state.load();
  runApp(NotebookApp(state: state));
}

class NotebookApp extends StatefulWidget {
  const NotebookApp({super.key, required this.state});

  final NotebookState state;

  @override
  State<NotebookApp> createState() => _NotebookAppState();
}

class _NotebookAppState extends State<NotebookApp> {
  late final AppRouterDelegate _routerDelegate;
  late final AppRouteParser _routeParser;

  @override
  void initState() {
    super.initState();
    _routerDelegate = AppRouterDelegate();
    _routeParser = AppRouteParser();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: widget.state,
      child: MaterialApp.router(
        title: 'Notebook',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeParser,
      ),
    );
  }
}
