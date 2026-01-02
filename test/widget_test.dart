import 'package:flutter_test/flutter_test.dart';

import 'package:notebook/main.dart';
import 'package:notebook/core/state/notebook_state.dart';
import 'package:notebook/core/storage/storage_service.dart';
import 'package:notebook/models/notebook_data.dart';

class FakeStorageService extends StorageService {
  @override
  Future<NotebookData?> loadNotebookData() async => null;

  @override
  Future<void> saveNotebookData(NotebookData data) async {}
}

void main() {
  testWidgets('App loads planner shell', (tester) async {
    final state = NotebookState(FakeStorageService());
    await tester.pumpWidget(NotebookApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Notebook'), findsOneWidget);
    expect(find.text('Daily Planner'), findsOneWidget);
  });
}
