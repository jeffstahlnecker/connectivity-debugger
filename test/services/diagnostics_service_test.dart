import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_debugger/services/diagnostics_service.dart';
import 'package:connectivity_debugger/models/device_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sim_data/sim_data.dart';
import 'package:device_info_plus/device_info_plus.dart';

@GenerateMocks([Connectivity, ISimDataProvider, DeviceInfoPlugin])
import 'diagnostics_service_test.mocks.dart';

class FakeSimCard extends Fake implements SimCard {
  @override
  String get carrierName => 'TestCarrier';
  @override
  String get countryCode => 'US';
  @override
  String get displayName => 'Test SIM';
  @override
  bool get isDataRoaming => false;
  @override
  bool get isNetworkRoaming => false;
  @override
  int get mcc => 310;
  @override
  int get mnc => 260;
  @override
  int get slotIndex => 0;
  @override
  String get serialNumber => '1234567890';
  @override
  int get subscriptionId => 1;
}

class FakeBaseDeviceInfo extends Fake implements BaseDeviceInfo {
  @override
  Map<String, dynamic> get data => {};
}

void main() {
  late DiagnosticsService diagnosticsService;
  late MockConnectivity mockConnectivity;
  late MockISimDataProvider mockSimDataProvider;
  late MockDeviceInfoPlugin mockDeviceInfoPlugin;

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockSimDataProvider = MockISimDataProvider();
    mockDeviceInfoPlugin = MockDeviceInfoPlugin();
    diagnosticsService = DiagnosticsService(
      connectivity: mockConnectivity,
      deviceInfo: mockDeviceInfoPlugin,
      simDataProvider: mockSimDataProvider,
    );
  });

  test(
    'should return DeviceStatus with correct values when all checks pass',
    () async {
      // Arrange
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) => Future.value(ConnectivityResult.mobile));
      when(
        mockDeviceInfoPlugin.deviceInfo,
      ).thenAnswer((_) => Future.value(FakeBaseDeviceInfo()));
      when(
        mockSimDataProvider.getSimData(),
      ).thenAnswer((_) => Future.value(SimData([FakeSimCard()])));

      // Act
      final status = await diagnosticsService.performDiagnostics();

      // Assert
      expect(status.isAirplaneMode, false);
      expect(status.isSimInserted, true);
      expect(status.isMobileDataEnabled, true);
      expect(status.carrierName, 'TestCarrier');
      expect(status.countryCode, 'US');
      expect(status.iccid, '1234567890');
      expect(status.imsi, '1');
    },
  );

  test('should detect airplane mode', () async {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) => Future.value(ConnectivityResult.none));
    when(
      mockDeviceInfoPlugin.deviceInfo,
    ).thenAnswer((_) => Future.value(FakeBaseDeviceInfo()));
    when(
      mockSimDataProvider.getSimData(),
    ).thenAnswer((_) => Future.value(SimData([FakeSimCard()])));

    final status = await diagnosticsService.performDiagnostics();
    expect(status.isAirplaneMode, true);
  });

  test('should detect missing SIM', () async {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) => Future.value(ConnectivityResult.mobile));
    when(
      mockDeviceInfoPlugin.deviceInfo,
    ).thenAnswer((_) => Future.value(FakeBaseDeviceInfo()));
    when(
      mockSimDataProvider.getSimData(),
    ).thenAnswer((_) => Future.value(SimData([])));

    final status = await diagnosticsService.performDiagnostics();
    expect(status.isSimInserted, false);
  });

  test('should detect mobile data disabled', () async {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) => Future.value(ConnectivityResult.none));
    when(
      mockDeviceInfoPlugin.deviceInfo,
    ).thenAnswer((_) => Future.value(FakeBaseDeviceInfo()));
    when(
      mockSimDataProvider.getSimData(),
    ).thenAnswer((_) => Future.value(SimData([FakeSimCard()])));

    final status = await diagnosticsService.performDiagnostics();
    expect(status.isMobileDataEnabled, false);
  });

  test('should detect DNS resolution failure', () async {
    // Skipped until DNS logic is mockable
  }, skip: true);

  test('should detect public IP unreachable', () async {
    // Skipped until public IP logic is mockable
  }, skip: true);

  test('should generate correct summary for all passing', () {
    final status = DeviceStatus(
      isAirplaneMode: false,
      isSimInserted: true,
      isMobileDataEnabled: true,
      canResolveDns: true,
      canReachPublicIp: true,
    );
    final summary = diagnosticsService.generateSummary(status);
    expect(summary, contains('All connectivity checks passed'));
  });

  test('should generate correct summary for failures', () {
    final status = DeviceStatus(
      isAirplaneMode: true,
      isSimInserted: false,
      isMobileDataEnabled: false,
      canResolveDns: false,
      canReachPublicIp: false,
    );
    final summary = diagnosticsService.generateSummary(status);
    expect(summary, contains('Airplane mode is enabled'));
    expect(summary, contains('No SIM card detected'));
    expect(summary, contains('Mobile data is disabled'));
    expect(summary, contains('DNS resolution failed'));
    expect(summary, contains('Cannot reach public IP'));
  });
}
