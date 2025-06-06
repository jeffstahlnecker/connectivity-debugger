class Settings {
  String? diagnosticsEmail;

  Settings({this.diagnosticsEmail});

  factory Settings.fromJson(Map<String, dynamic> json) =>
      Settings(diagnosticsEmail: json['diagnosticsEmail'] as String?);

  Map<String, dynamic> toJson() => {'diagnosticsEmail': diagnosticsEmail};
}
