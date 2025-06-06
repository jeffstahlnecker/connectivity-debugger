// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speed_test_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeedTestResult _$SpeedTestResultFromJson(Map<String, dynamic> json) =>
    SpeedTestResult(
      downloadMbps: (json['downloadMbps'] as num).toDouble(),
      uploadMbps: (json['uploadMbps'] as num).toDouble(),
      server: json['server'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] as String?,
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SpeedTestResultToJson(SpeedTestResult instance) =>
    <String, dynamic>{
      'downloadMbps': instance.downloadMbps,
      'uploadMbps': instance.uploadMbps,
      'server': instance.server,
      'timestamp': instance.timestamp.toIso8601String(),
      'error': instance.error,
      'latencyMs': instance.latencyMs,
    };
