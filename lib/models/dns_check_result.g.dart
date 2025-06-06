// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_check_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DnsCheckResult _$DnsCheckResultFromJson(Map<String, dynamic> json) =>
    DnsCheckResult(
      target: json['target'] as String,
      success: json['success'] as bool,
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      error: json['error'] as String?,
      type: $enumDecode(_$CheckTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$DnsCheckResultToJson(DnsCheckResult instance) =>
    <String, dynamic>{
      'target': instance.target,
      'success': instance.success,
      'latencyMs': instance.latencyMs,
      'error': instance.error,
      'type': _$CheckTypeEnumMap[instance.type]!,
    };

const _$CheckTypeEnumMap = {
  CheckType.dns: 'dns',
  CheckType.reachability: 'reachability',
};
