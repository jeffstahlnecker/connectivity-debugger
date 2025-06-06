import 'package:json_annotation/json_annotation.dart';

part 'dns_check_result.g.dart';

enum CheckType { dns, reachability }

@JsonSerializable()
class DnsCheckResult {
  final String target;
  final bool success;
  final int? latencyMs;
  final String? error;
  final CheckType type;

  DnsCheckResult({
    required this.target,
    required this.success,
    this.latencyMs,
    this.error,
    required this.type,
  });

  factory DnsCheckResult.fromJson(Map<String, dynamic> json) =>
      _$DnsCheckResultFromJson(json);
  Map<String, dynamic> toJson() => _$DnsCheckResultToJson(this);
}
