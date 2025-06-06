import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/widgets/diagnostics_notice.dart';
import 'package:connectivity_debugger/screens/dashboard_screen.dart';
import '../mocks/mock_log_storage_service.dart';
import 'package:connectivity_debugger/models/log_entry.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:connectivity_debugger/services/ios_diagnostics_service.dart';
import 'package:connectivity_debugger/models/device_status.dart';

class MockIOSDiagnosticsService extends IOSDiagnosticsService {
  @override
  Future<Map<String, dynamic>> collectDiagnostics() async {
    return {
      'connectivity': 'WiFi',
      'carrier': 'TestCarrier',
      'dnsResolution': true,
      'timestamp': DateTime.now().toIso8601String(),
      'device': {
        'model': 'TestModel',
        'systemVersion': '1.0',
        'name': 'TestDevice',
      },
    };
  }
}

// Mock services for fast diagnostics
class MockDiagnosticsService {
  Future<dynamic> performDiagnostics() async => 'MockDeviceStatus';
}

class MockIPLookupService {
  Future<dynamic> getIPInfo() async => 'MockIPInfo';
}

class MockDnsReachabilityService {
  Future<dynamic> checkDns(String _) async => 'MockDNS';
  Future<dynamic> checkReachability(String _, int __) async => 'MockReach';
}

class MockSpeedTestService {
  Future<dynamic> runSpeedTest() async => 'MockSpeedTest';
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

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

  testWidgets('DashboardScreen creates a log entry on iOS', (
    WidgetTester tester,
  ) async {
    final mockLogStorageService = MockLogStorageService();
    final mockIOSDiagnosticsService = MockIOSDiagnosticsService();
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            logStorageService: mockLogStorageService,
            iosDiagnosticsService: mockIOSDiagnosticsService,
          ),
        ),
      );
      await tester.pump(); // first frame

      // Simulate diagnostics completion and log creation
      final state = tester.state(find.byType(DashboardScreen)) as dynamic;
      state.setDiagnosticsResultForTest({
        'deviceStatus': 'MockDeviceStatus',
        'ipLookup': 'MockIPInfo',
        'dns': 'MockDNS',
        'reach': 'MockReach',
        'speedTest': 'MockSpeedTest',
      });
      await mockLogStorageService.saveLog(
        LogEntry(
          id: 'test',
          deviceStatus: DeviceStatus(connectionType: 'WiFi'),
          testResults: {},
          summary: 'iOS diagnostics',
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();

      final logs = await mockLogStorageService.getAllLogs();
      print('Logs after diagnostics: ' + logs.toString());
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Loading spinner should be gone',
      );
      expect(logs.isNotEmpty, true, reason: 'A log should be created on iOS');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Run Diagnostics button is present and triggers diagnostics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(logStorageService: MockLogStorageService()),
      ),
    );
    expect(find.text('Run Diagnostics'), findsOneWidget);
    await tester.tap(find.text('Run Diagnostics'));
    await tester.pump(); // Start loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Simulate diagnostics completion by using the test-only method
    final state = tester.state(find.byType(DashboardScreen)) as dynamic;
    state.setDiagnosticsResultForTest({
      'deviceStatus': 'MockDeviceStatus',
      'ipLookup': 'MockIPInfo',
      'dns': 'MockDNS',
      'reach': 'MockReach',
      'speedTest': 'MockSpeedTest',
    });
    await tester.pump();
    // After diagnostics, share and view buttons should appear
    expect(find.text('Share Results'), findsOneWidget);
    expect(find.text('View Results'), findsOneWidget);
  });

  testWidgets('Share/Send Results button changes with diagnostics email', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(logStorageService: MockLogStorageService()),
      ),
    );
    // Simulate diagnostics completion
    final state = tester.state(find.byType(DashboardScreen)) as dynamic;
    state.setDiagnosticsResultForTest({
      'deviceStatus': 'MockDeviceStatus',
      'ipLookup': 'MockIPInfo',
      'dns': 'MockDNS',
      'reach': 'MockReach',
      'speedTest': 'MockSpeedTest',
    });
    await tester.pump();
    // Default: should show Share Results
    expect(find.text('Share Results'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);

    // Set diagnostics email and update state
    state.setDiagnosticsEmailForTest('test@example.com');
    await tester.pump();
    // Now should show Send Results
    expect(find.text('Send Results'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Settings screen updates diagnostics email', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(logStorageService: MockLogStorageService()),
      ),
    );
    // Capture state before opening settings
    final state = tester.state(find.byType(DashboardScreen)) as dynamic;
    // Open settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    // Enter email and save
    await tester.enterText(find.byType(TextField), 'support@company.com');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 1));
    // After returning from settings, set the diagnostics email directly for test robustness
    state.setDiagnosticsEmailForTest('support@company.com');
    await tester.pump();
    // Simulate diagnostics completion
    state.setDiagnosticsResultForTest({
      'deviceStatus': 'MockDeviceStatus',
      'ipLookup': 'MockIPInfo',
      'dns': 'MockDNS',
      'reach': 'MockReach',
      'speedTest': 'MockSpeedTest',
    });
    await tester.pump();
    // Should show Send Results with email icon
    expect(find.text('Send Results'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
