import 'package:json_annotation/json_annotation.dart';

part 'speed_test_result.g.dart';

@JsonSerializable()
class SpeedTestResult {
  final double downloadMbps;
  final double uploadMbps;
  final String server;
  final DateTime timestamp;
  final String? error;
  final int? latencyMs;

  SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.server,
    required this.timestamp,
    this.error,
    this.latencyMs,
  });

  factory SpeedTestResult.fromJson(Map<String, dynamic> json) =>
      _$SpeedTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$SpeedTestResultToJson(this);

  @override
  String toString() {
    return 'SpeedTestResult(download: ${downloadMbps.toStringAsFixed(2)} Mbps, '
        'upload: ${uploadMbps.toStringAsFixed(2)} Mbps, '
        'server: $server, '
        'latency: ${latencyMs ?? "N/A"} ms)';
  }
}
