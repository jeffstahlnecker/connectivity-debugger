import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/log_entry.dart';

class LogStorageService {
  static const String _boxName = 'diagnostic_logs';
  late Box<Map<dynamic, dynamic>> _box;
  final _uuid = Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  Future<void> saveLog(LogEntry log) async {
    final logWithId = log.id.isNotEmpty ? log : log.copyWith(id: _uuid.v4());
    await _box.put(logWithId.id, logWithId.toJson());
  }

  // Helper to recursively cast map keys to String
  Map<String, dynamic> _castMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _castMap(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  Future<List<LogEntry>> getAllLogs() async {
    final logs = <LogEntry>[];
    for (var i = 0; i < _box.length; i++) {
      final logData = _box.getAt(i);
      if (logData != null) {
        logs.add(LogEntry.fromJson(_castMap(logData)));
      }
    }
    return logs;
  }

  Future<void> deleteLog(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAllLogs() async {
    await _box.clear();
  }

  Future<String> exportLogsAsJson() async {
    final logs = await getAllLogs();
    final jsonList = logs.map((log) => log.toJson()).toList();
    return jsonList.toString();
  }

  Future<String> exportLogsAsText() async {
    final logs = await getAllLogs();
    final buffer = StringBuffer();

    for (final log in logs) {
      buffer.writeln('Log Entry: ${log.id}');
      buffer.writeln('Timestamp: ${log.timestamp}');
      buffer.writeln('Summary: ${log.summary}');
      buffer.writeln('Device Status:');
      buffer.writeln('  ICCID: ${log.deviceStatus.iccid}');
      buffer.writeln('  IMSI: ${log.deviceStatus.imsi}');
      buffer.writeln('  Signal Strength: ${log.deviceStatus.signalStrength}');
      buffer.writeln('  Connection Type: ${log.deviceStatus.connectionType}');
      buffer.writeln('  Carrier: ${log.deviceStatus.carrierName}');
      buffer.writeln('  Country Code: ${log.deviceStatus.countryCode}');
      buffer.writeln('  IP Address: ${log.deviceStatus.ipAddress}');
      buffer.writeln('  Data Roaming: ${log.deviceStatus.isDataRoaming}');
      buffer.writeln('  Airplane Mode: ${log.deviceStatus.isAirplaneMode}');
      buffer.writeln('  SIM Inserted: ${log.deviceStatus.isSimInserted}');
      buffer.writeln(
        '  Mobile Data Enabled: ${log.deviceStatus.isMobileDataEnabled}',
      );
      buffer.writeln('  DNS Resolution: ${log.deviceStatus.canResolveDns}');
      buffer.writeln(
        '  Public IP Reachable: ${log.deviceStatus.canReachPublicIp}',
      );
      buffer.writeln('Test Results:');
      log.testResults.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
      buffer.writeln('---');
    }

    return buffer.toString();
  }
}
