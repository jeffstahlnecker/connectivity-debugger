import 'package:connectivity_debugger/models/log_entry.dart';
import 'package:connectivity_debugger/services/log_storage_service.dart';

class MockLogStorageService implements LogStorageService {
  final List<LogEntry> _logs = [];

  @override
  Future<void> init() async {
    // No-op for testing
  }

  @override
  Future<void> saveLog(LogEntry log) async {
    _logs.add(log);
  }

  Future<List<LogEntry>> getLogs() async {
    return _logs;
  }

  @override
  Future<List<LogEntry>> getAllLogs() async {
    return _logs;
  }

  Future<void> clearLogs() async {
    _logs.clear();
  }

  @override
  Future<void> clearAllLogs() async {
    _logs.clear();
  }

  @override
  Future<void> deleteLog(String id) async {
    _logs.removeWhere((log) => log.id == id);
  }

  @override
  Future<String> exportLogsAsJson() async {
    return '[]'; // Mock implementation
  }

  @override
  Future<String> exportLogsAsText() async {
    return ''; // Mock implementation
  }

  Future<void> importLogsFromJson(String json) async {
    // Mock implementation
  }
}
