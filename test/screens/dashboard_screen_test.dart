import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/widgets/diagnostics_notice.dart';
import 'package:connectivity_debugger/screens/dashboard_screen.dart';
import '../mocks/mock_log_storage_service.dart';

void main() {
  testWidgets('DiagnosticsNotice shows on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DiagnosticsNotice(isIOSOverride: true))),
    );
    expect(
      find.text(
        'Note: Due to iOS system restrictions, only basic connectivity and device info can be collected. SIM and cellular diagnostics are not available.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('DiagnosticsNotice does not show on non-iOS', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DiagnosticsNotice(isIOSOverride: false)),
      ),
    );
    expect(
      find.text(
        'Note: Due to iOS system restrictions, only basic connectivity and device info can be collected. SIM and cellular diagnostics are not available.',
      ),
      findsNothing,
    );
  });

  testWidgets('DashboardScreen renders and shows refresh button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(logStorageService: MockLogStorageService()),
      ),
    );
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
