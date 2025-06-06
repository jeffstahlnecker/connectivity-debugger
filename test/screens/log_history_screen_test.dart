import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/screens/log_history_screen.dart';
import 'package:connectivity_debugger/models/log_entry.dart';
import 'package:connectivity_debugger/models/device_status.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_debugger/services/log_storage_service.dart';

class MockLogStorageService extends LogStorageService {
  List<LogEntry> logs = [];
  @override
  Future<List<LogEntry>> getAllLogs() async => logs;
}

void main() {
  group('LogHistoryScreen', () {
    testWidgets('shows empty state when no logs', (WidgetTester tester) async {
      final mockService = MockLogStorageService();
      mockService.logs = [];
      await tester.pumpWidget(
        MaterialApp(home: LogHistoryScreen(logStorageService: mockService)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No logs found.'), findsOneWidget);
    });

    testWidgets('shows logs and opens details dialog', (
      WidgetTester tester,
    ) async {
      final mockService = MockLogStorageService();
      final timestamp = DateTime(2025, 5, 30, 0, 16, 39, 627148);
      final log = LogEntry(
        id: 'id1',
        deviceStatus: DeviceStatus(iccid: '123', timestamp: timestamp),
        testResults: {'airplaneMode': true},
        summary: 'Test summary',
        timestamp: timestamp,
      );
      mockService.logs = [log];
      await tester.pumpWidget(
        MaterialApp(home: LogHistoryScreen(logStorageService: mockService)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Test summary'), findsOneWidget);
      // Tap the log to open dialog
      await tester.tap(find.text('Test summary'));
      await tester.pumpAndSettle();
      expect(find.text('Log Details'), findsOneWidget);
      expect(find.textContaining('Test summary'), findsWidgets);
      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Log Details'), findsNothing);
    });
  });
}
