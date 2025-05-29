import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class IOSDiagnosticsService {
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const MethodChannel _carrierChannel = MethodChannel(
    'custom.carrier.info',
  );

  Future<String> getCarrierName() async {
    try {
      final String carrier = await _carrierChannel.invokeMethod(
        'getCarrierName',
      );
      return carrier;
    } catch (e) {
      return 'Unavailable';
    }
  }

  Future<Map<String, dynamic>> collectDiagnostics() async {
    final Map<String, dynamic> diagnostics = {};

    // Connectivity status (wifi/cellular/none)
    final connectivityResult = await _connectivity.checkConnectivity();
    String connectivityLabel;
    switch (connectivityResult) {
      case ConnectivityResult.mobile:
        connectivityLabel = 'Cellular';
        break;
      case ConnectivityResult.wifi:
        connectivityLabel = 'WiFi';
        break;
      case ConnectivityResult.ethernet:
        connectivityLabel = 'Ethernet';
        break;
      case ConnectivityResult.none:
        connectivityLabel = 'None';
        break;
      default:
        connectivityLabel = 'Other';
    }
    diagnostics['connectivity'] = connectivityLabel;

    // Device info
    final iosInfo = await _deviceInfo.iosInfo;
    diagnostics['device'] = {
      'model': iosInfo.utsname.machine,
      'systemVersion': iosInfo.systemVersion,
      'name': iosInfo.name,
    };

    // Carrier info (via platform channel)
    diagnostics['carrier'] = await getCarrierName();

    // DNS/public IP check
    try {
      final result = await InternetAddress.lookup('google.com');
      diagnostics['dnsResolution'] = result.isNotEmpty;
    } catch (e) {
      diagnostics['dnsResolution'] = false;
    }

    // Timestamp
    diagnostics['timestamp'] = DateTime.now().toIso8601String();

    return diagnostics;
  }
}
