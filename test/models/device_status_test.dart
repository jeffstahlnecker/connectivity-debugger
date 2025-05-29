import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/models/device_status.dart';

void main() {
  group('DeviceStatus', () {
    test('creates instance with all fields', () {
      final status = DeviceStatus(
        iccid: '123',
        imsi: '456',
        carrierName: 'Test Carrier',
        countryCode: 'US',
        isDataRoaming: true,
        isAirplaneMode: false,
        isSimInserted: true,
        isMobileDataEnabled: true,
        connectionType: '4G',
        signalStrength: -85,
        ipAddress: '192.168.1.1',
        canResolveDns: true,
        canReachPublicIp: true,
        timestamp: DateTime(2025, 5, 30, 0, 16, 39, 627148),
      );

      expect(status.iccid, '123');
      expect(status.imsi, '456');
      expect(status.carrierName, 'Test Carrier');
      expect(status.countryCode, 'US');
      expect(status.isDataRoaming, true);
      expect(status.isAirplaneMode, false);
      expect(status.isSimInserted, true);
      expect(status.isMobileDataEnabled, true);
      expect(status.connectionType, '4G');
      expect(status.signalStrength, -85);
      expect(status.ipAddress, '192.168.1.1');
      expect(status.canResolveDns, true);
      expect(status.canReachPublicIp, true);
      expect(status.timestamp, DateTime(2025, 5, 30, 0, 16, 39, 627148));
    });

    test('creates instance with minimal fields', () {
      final status = DeviceStatus(
        iccid: '123',
        timestamp: DateTime(2025, 5, 30, 0, 16, 39, 627148),
      );

      expect(status.iccid, '123');
      expect(status.imsi, null);
      expect(status.carrierName, null);
      expect(status.countryCode, null);
      expect(status.isDataRoaming, false);
      expect(status.isAirplaneMode, false);
      expect(status.isSimInserted, false);
      expect(status.isMobileDataEnabled, false);
      expect(status.connectionType, null);
      expect(status.signalStrength, null);
      expect(status.ipAddress, null);
      expect(status.canResolveDns, false);
      expect(status.canReachPublicIp, false);
      expect(status.timestamp, DateTime(2025, 5, 30, 0, 16, 39, 627148));
    });

    test('equality', () {
      final timestamp = DateTime(2025, 5, 30, 0, 16, 39, 627148);
      final status1 = DeviceStatus(iccid: '123', timestamp: timestamp);
      final status2 = DeviceStatus(iccid: '123', timestamp: timestamp);

      expect(status1, equals(status2));
    });
  });
}
