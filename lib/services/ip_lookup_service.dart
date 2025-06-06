import 'dart:convert';
import 'package:http/http.dart' as http;

class IPLookupResult {
  final String ip;
  final String? asn;
  final String? org;
  final String? country;
  final String? city;
  final DateTime fetchedAt;

  IPLookupResult({
    required this.ip,
    this.asn,
    this.org,
    this.country,
    this.city,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'asn': asn,
      'org': org,
      'country': country,
      'city': city,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }
}

class IPLookupService {
  IPLookupResult? _cache;
  DateTime? _cacheTime;
  final Duration cacheDuration;
  final http.Client _client;

  IPLookupService({
    this.cacheDuration = const Duration(minutes: 15),
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<IPLookupResult?> getIPInfo() async {
    final now = DateTime.now();
    if (_cache != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < cacheDuration) {
      return _cache;
    }
    IPLookupResult? result;
    try {
      result = await _fetchFromIpInfo();
    } catch (_) {
      result = await _fetchFromIpApi();
    }
    if (result != null) {
      _cache = result;
      _cacheTime = now;
    }
    return result;
  }

  Future<IPLookupResult?> _fetchFromIpInfo() async {
    final response = await _client.get(Uri.parse('https://ipinfo.io/json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return IPLookupResult(
        ip: data['ip'] ?? '',
        asn: data['org'],
        org: data['org'],
        country: data['country'],
        city: data['city'],
      );
    } else {
      throw Exception('ipinfo.io failed');
    }
  }

  Future<IPLookupResult?> _fetchFromIpApi() async {
    final response = await _client.get(Uri.parse('http://ip-api.com/json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return IPLookupResult(
        ip: data['query'] ?? '',
        asn: data['as'],
        org: data['org'],
        country: data['countryCode'],
        city: data['city'],
      );
    } else {
      throw Exception('ip-api.com failed');
    }
  }
}
