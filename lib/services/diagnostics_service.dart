import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/device_status.dart';
// Only import sim_data on Android
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'sim_info_service.dart';

class DiagnosticsService {
  final Connectivity connectivity;
  final DeviceInfoPlugin deviceInfo;

  DiagnosticsService({Connectivity? connectivity, DeviceInfoPlugin? deviceInfo})
    : connectivity = connectivity ?? Connectivity(),
      deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<DeviceStatus> performDiagnostics() async {
    final connectivityResult = await connectivity.checkConnectivity();

    String? carrierName;
    String? countryCode;
    String? iccid;
    String? imsi;
    int? signalStrength;
    bool isDataRoaming = false;
    bool isSimInserted = false;
    String? simNumber;

    if (Platform.isAndroid) {
      final simInfo = await SimInfoService.getSimInfo();
      if (simInfo != null && simInfo['error'] == null) {
        carrierName = simInfo['carrierName'] as String?;
        countryCode = simInfo['countryCode'] as String?;
        iccid = simInfo['iccid'] as String?;
        isDataRoaming = simInfo['isDataRoaming'] == true;
        isSimInserted = simInfo['isSimInserted'] == true;
        simNumber = simInfo['number'] as String?;
        // imsi and signalStrength not available from this method
      }
    }

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
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            ipAddress = addr.address;
            break;
          }
        }
        if (ipAddress != null) break;
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
      iccid: iccid,
      imsi: imsi,
      signalStrength: signalStrength,
      connectionType: _getConnectionType(connectivityResult),
      carrierName: carrierName,
      countryCode: countryCode,
      isDataRoaming: isDataRoaming,
      isAirplaneMode: isAirplaneMode,
      isSimInserted: isSimInserted,
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
