import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/services/ios_diagnostics_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IOSDiagnosticsService', () {
    late IOSDiagnosticsService service;
    late MockConnectivity mockConnectivity;
    late MockDeviceInfoPlugin mockDeviceInfo;
    const MethodChannel channel = MethodChannel('custom.carrier.info');

    setUp(() {
      mockConnectivity = MockConnectivity();
      mockDeviceInfo = MockDeviceInfoPlugin();
      service = IOSDiagnosticsService();
    });

    test('getCarrierName returns carrier from platform channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getCarrierName') {
              return 'TestCarrier';
            }
            return null;
          });
      final carrier = await service.getCarrierName();
      expect(carrier, 'TestCarrier');
    });

    test('getCarrierName returns Unavailable on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => throw PlatformException(code: 'ERROR'),
          );
      final carrier = await service.getCarrierName();
      expect(carrier, 'Unavailable');
    });
  });
}
