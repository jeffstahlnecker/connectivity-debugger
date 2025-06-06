import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SimInfoService {
  static const MethodChannel _channel = MethodChannel(
    'com.connectivity_debugger/sim_info',
  );

  static Future<bool> requestPhonePermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<Map<String, dynamic>?> getSimInfo() async {
    if (!Platform.isAndroid) return null;
    final hasPermission = await requestPhonePermission();
    if (!hasPermission) {
      return {'error': 'READ_PHONE_STATE permission not granted'};
    }
    try {
      final result = await _channel.invokeMethod<Map>('getSimInfo');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      return {'error': e.message};
    }
  }
}
