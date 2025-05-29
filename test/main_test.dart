import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/main.dart';
import 'mocks/mock_log_storage_service.dart';

void main() {
  testWidgets('App starts and renders dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(logStorageService: MockLogStorageService()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
