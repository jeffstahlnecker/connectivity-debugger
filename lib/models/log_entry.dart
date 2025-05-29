import 'package:equatable/equatable.dart';
import 'device_status.dart';

class LogEntry extends Equatable {
  final String id;
  final DeviceStatus deviceStatus;
  final Map<String, dynamic> testResults;
  final String summary;
  final DateTime timestamp;

  LogEntry({
    required this.id,
    required this.deviceStatus,
    required this.testResults,
    required this.summary,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  LogEntry copyWith({
    String? id,
    DeviceStatus? deviceStatus,
    Map<String, dynamic>? testResults,
    String? summary,
    DateTime? timestamp,
  }) {
    return LogEntry(
      id: id ?? this.id,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      testResults: testResults ?? this.testResults,
      summary: summary ?? this.summary,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceStatus': deviceStatus.toJson(),
      'testResults': testResults,
      'summary': summary,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      deviceStatus: DeviceStatus.fromJson(json['deviceStatus']),
      testResults: json['testResults'],
      summary: json['summary'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    deviceStatus,
    testResults,
    summary,
    timestamp,
  ];
}
