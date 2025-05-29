import 'package:equatable/equatable.dart';

class DeviceStatus extends Equatable {
  final String? iccid;
  final String? imsi;
  final int? signalStrength;
  final String? connectionType;
  final String? carrierName;
  final String? countryCode;
  final bool isDataRoaming;
  final bool isAirplaneMode;
  final bool isSimInserted;
  final bool isMobileDataEnabled;
  final String? ipAddress;
  final bool canResolveDns;
  final bool canReachPublicIp;
  final DateTime timestamp;

  DeviceStatus({
    this.iccid,
    this.imsi,
    this.signalStrength,
    this.connectionType,
    this.carrierName,
    this.countryCode,
    this.isDataRoaming = false,
    this.isAirplaneMode = false,
    this.isSimInserted = false,
    this.isMobileDataEnabled = false,
    this.ipAddress,
    this.canResolveDns = false,
    this.canReachPublicIp = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  DeviceStatus copyWith({
    String? iccid,
    String? imsi,
    int? signalStrength,
    String? connectionType,
    String? carrierName,
    String? countryCode,
    bool? isDataRoaming,
    bool? isAirplaneMode,
    bool? isSimInserted,
    bool? isMobileDataEnabled,
    String? ipAddress,
    bool? canResolveDns,
    bool? canReachPublicIp,
    DateTime? timestamp,
  }) {
    return DeviceStatus(
      iccid: iccid ?? this.iccid,
      imsi: imsi ?? this.imsi,
      signalStrength: signalStrength ?? this.signalStrength,
      connectionType: connectionType ?? this.connectionType,
      carrierName: carrierName ?? this.carrierName,
      countryCode: countryCode ?? this.countryCode,
      isDataRoaming: isDataRoaming ?? this.isDataRoaming,
      isAirplaneMode: isAirplaneMode ?? this.isAirplaneMode,
      isSimInserted: isSimInserted ?? this.isSimInserted,
      isMobileDataEnabled: isMobileDataEnabled ?? this.isMobileDataEnabled,
      ipAddress: ipAddress ?? this.ipAddress,
      canResolveDns: canResolveDns ?? this.canResolveDns,
      canReachPublicIp: canReachPublicIp ?? this.canReachPublicIp,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iccid': iccid,
      'imsi': imsi,
      'signalStrength': signalStrength,
      'connectionType': connectionType,
      'carrierName': carrierName,
      'countryCode': countryCode,
      'isDataRoaming': isDataRoaming,
      'isAirplaneMode': isAirplaneMode,
      'isSimInserted': isSimInserted,
      'isMobileDataEnabled': isMobileDataEnabled,
      'ipAddress': ipAddress,
      'canResolveDns': canResolveDns,
      'canReachPublicIp': canReachPublicIp,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      iccid: json['iccid'],
      imsi: json['imsi'],
      signalStrength: json['signalStrength'],
      connectionType: json['connectionType'],
      carrierName: json['carrierName'],
      countryCode: json['countryCode'],
      isDataRoaming: json['isDataRoaming'] ?? false,
      isAirplaneMode: json['isAirplaneMode'] ?? false,
      isSimInserted: json['isSimInserted'] ?? false,
      isMobileDataEnabled: json['isMobileDataEnabled'] ?? false,
      ipAddress: json['ipAddress'],
      canResolveDns: json['canResolveDns'] ?? false,
      canReachPublicIp: json['canReachPublicIp'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  List<Object?> get props => [
    iccid,
    imsi,
    signalStrength,
    connectionType,
    carrierName,
    countryCode,
    isDataRoaming,
    isAirplaneMode,
    isSimInserted,
    isMobileDataEnabled,
    ipAddress,
    canResolveDns,
    canReachPublicIp,
    timestamp,
  ];
}
