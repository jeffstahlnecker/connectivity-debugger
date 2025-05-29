import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sim_data/sim_data.dart';
import '../models/device_status.dart';

abstract class ISimDataProvider {
  Future<SimData> getSimData();
}

class RealSimDataProvider implements ISimDataProvider {
  @override
  Future<SimData> getSimData() => SimDataPlugin.getSimData();
}

class DiagnosticsService {
  final Connectivity connectivity;
  final DeviceInfoPlugin deviceInfo;
  final ISimDataProvider simDataProvider;

  DiagnosticsService({
    Connectivity? connectivity,
    DeviceInfoPlugin? deviceInfo,
    ISimDataProvider? simDataProvider,
  }) : connectivity = connectivity ?? Connectivity(),
       deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       simDataProvider = simDataProvider ?? RealSimDataProvider();

  Future<DeviceStatus> performDiagnostics() async {
    final connectivityResult = await connectivity.checkConnectivity();
    final simDataResult = await simDataProvider.getSimData();

    // Get the first SIM card data (if available)
    final simCard = simDataResult.cards.isNotEmpty
        ? simDataResult.cards.first
        : null;

    // Check if mobile data is enabled
    final isMobileDataEnabled = connectivityResult == ConnectivityResult.mobile;

    // Check if airplane mode is enabled
    final isAirplaneMode = connectivityResult == ConnectivityResult.none;

    // Get IP address
    String? ipAddress;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('mobile')) {
          ipAddress = interface.addresses.first.address;
          break;
        }
      }
    } catch (e) {
      ipAddress = null;
    }

    // Check DNS resolution
    bool canResolveDns = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      canResolveDns = result.isNotEmpty;
    } catch (e) {
      canResolveDns = false;
    }

    // Check public IP reachability
    bool canReachPublicIp = false;
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: Duration(seconds: 5),
      );
      await socket.close();
      canReachPublicIp = true;
    } catch (e) {
      canReachPublicIp = false;
    }

    return DeviceStatus(
      iccid: simCard?.serialNumber, // Use serialNumber as ICCID equivalent
      imsi: simCard?.subscriptionId
          .toString(), // Use subscriptionId as IMSI equivalent
      signalStrength: null, // Not available
      connectionType: _getConnectionType(connectivityResult),
      carrierName: simCard?.carrierName,
      countryCode: simCard?.countryCode,
      isDataRoaming: simCard?.isDataRoaming ?? false,
      isAirplaneMode: isAirplaneMode,
      isSimInserted: simCard != null,
      isMobileDataEnabled: isMobileDataEnabled,
      ipAddress: ipAddress,
      canResolveDns: canResolveDns,
      canReachPublicIp: canReachPublicIp,
    );
  }

  String generateSummary(DeviceStatus status) {
    final issues = <String>[];

    if (status.isAirplaneMode) {
      issues.add('Airplane mode is enabled');
    }

    if (!status.isSimInserted) {
      issues.add('No SIM card detected');
    }

    if (!status.isMobileDataEnabled) {
      issues.add('Mobile data is disabled');
    }

    if (status.signalStrength != null && status.signalStrength! < -100) {
      issues.add('Weak signal strength');
    }

    if (!status.canResolveDns) {
      issues.add('DNS resolution failed');
    }

    if (!status.canReachPublicIp) {
      issues.add('Cannot reach public IP');
    }

    if (issues.isEmpty) {
      return 'All connectivity checks passed successfully';
    }

    return 'Issues detected:\n${issues.join('\n')}';
  }

  String? _getConnectionType(ConnectivityResult? result) {
    if (result == ConnectivityResult.mobile) {
      return 'Mobile';
    } else if (result == ConnectivityResult.wifi) {
      return 'WiFi';
    } else if (result == ConnectivityResult.ethernet) {
      return 'Ethernet';
    } else if (result == ConnectivityResult.bluetooth) {
      return 'Bluetooth';
    } else if (result == ConnectivityResult.none) {
      return 'None';
    }
    return null;
  }
}
