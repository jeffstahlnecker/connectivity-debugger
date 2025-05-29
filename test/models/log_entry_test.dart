import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/models/log_entry.dart';
import 'package:connectivity_debugger/models/device_status.dart';

void main() {
  group('LogEntry', () {
    final timestamp = DateTime(2025, 5, 30, 0, 16, 39, 627148);
    final deviceStatus = DeviceStatus(iccid: '123', timestamp: timestamp);

    test('creates instance with all fields', () {
      final logEntry = LogEntry(
        id: 'test-id',
        deviceStatus: deviceStatus,
        testResults: {'airplaneMode': true, 'simInserted': false},
        summary: 'Test summary',
        timestamp: timestamp,
      );

      expect(logEntry.id, 'test-id');
      expect(logEntry.deviceStatus, deviceStatus);
      expect(logEntry.testResults, {
        'airplaneMode': true,
        'simInserted': false,
      });
      expect(logEntry.summary, 'Test summary');
      expect(logEntry.timestamp, timestamp);
    });

    test('creates instance with minimal fields', () {
      final logEntry = LogEntry(
        id: 'test-id',
        deviceStatus: deviceStatus,
        testResults: {},
        summary: '',
        timestamp: timestamp,
      );

      expect(logEntry.id, 'test-id');
      expect(logEntry.deviceStatus, deviceStatus);
      expect(logEntry.testResults, {});
      expect(logEntry.summary, '');
      expect(logEntry.timestamp, timestamp);
    });

    test('toJson and fromJson', () {
      final logEntry = LogEntry(
        id: 'test-id',
        deviceStatus: deviceStatus,
        testResults: {'airplaneMode': true, 'simInserted': false},
        summary: 'Test summary',
        timestamp: timestamp,
      );

      final json = logEntry.toJson();
      final fromJson = LogEntry.fromJson(json);

      expect(fromJson.id, logEntry.id);
      expect(fromJson.deviceStatus.iccid, logEntry.deviceStatus.iccid);
      expect(fromJson.testResults, logEntry.testResults);
      expect(fromJson.summary, logEntry.summary);
      expect(fromJson.timestamp, logEntry.timestamp);
    });

    test('equality', () {
      final logEntry1 = LogEntry(
        id: 'test-id',
        deviceStatus: deviceStatus,
        testResults: {},
        summary: '',
        timestamp: timestamp,
      );
      final logEntry2 = LogEntry(
        id: 'test-id',
        deviceStatus: deviceStatus,
        testResults: {},
        summary: '',
        timestamp: timestamp,
      );

      expect(logEntry1, equals(logEntry2));
    });

    test('copyWith returns updated object', () {
      final logEntry = LogEntry(
        id: 'test-id',
        deviceStatus: deviceStatus,
        testResults: {},
        summary: '',
        timestamp: timestamp,
      );
      final updated = logEntry.copyWith(id: 'new-id', summary: 'New summary');

      expect(updated.id, 'new-id');
      expect(updated.summary, 'New summary');
      expect(updated.deviceStatus, logEntry.deviceStatus);
      expect(updated.testResults, logEntry.testResults);
      expect(updated.timestamp, logEntry.timestamp);
    });
  });
}
