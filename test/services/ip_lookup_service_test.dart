import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_debugger/services/ip_lookup_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert';

import 'ip_lookup_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('IPLookupService', () {
    late MockClient mockClient;
    late IPLookupService service;

    setUp(() {
      mockClient = MockClient();
      // Default stub to avoid null fallback
      when(
        mockClient.get(any),
      ).thenAnswer((_) async => http.Response('{}', 404));
      service = IPLookupService(client: mockClient);
    });

    test('parses ipinfo.io response', () async {
      final ipinfoJson = json.encode({
        'ip': '1.2.3.4',
        'org': 'AS1234 TestOrg',
        'country': 'US',
        'city': 'New York',
      });
      when(
        mockClient.get(Uri.parse('https://ipinfo.io/json')),
      ).thenAnswer((_) async => http.Response(ipinfoJson, 200));

      final result = await service.getIPInfo();
      expect(result, isNotNull);
      expect(result!.ip, '1.2.3.4');
      expect(result.org, 'AS1234 TestOrg');
      expect(result.country, 'US');
      expect(result.city, 'New York');
    });

    test('falls back to ip-api.com on ipinfo.io error', () async {
      when(
        mockClient.get(Uri.parse('https://ipinfo.io/json')),
      ).thenAnswer((_) async => http.Response('Internal Error', 500));
      final ipApiJson = json.encode({
        'query': '5.6.7.8',
        'as': 'AS5678 FallbackOrg',
        'org': 'FallbackOrg',
        'countryCode': 'DE',
        'city': 'Berlin',
      });
      when(
        mockClient.get(Uri.parse('http://ip-api.com/json')),
      ).thenAnswer((_) async => http.Response(ipApiJson, 200));

      final result = await service.getIPInfo();
      expect(result, isNotNull);
      expect(result!.ip, '5.6.7.8');
      expect(result.org, 'FallbackOrg');
      expect(result.country, 'DE');
      expect(result.city, 'Berlin');
    });

    test('caches result for 15 minutes', () async {
      final ipinfoJson = json.encode({
        'ip': '1.2.3.4',
        'org': 'AS1234 TestOrg',
        'country': 'US',
        'city': 'New York',
      });
      when(
        mockClient.get(Uri.parse('https://ipinfo.io/json')),
      ).thenAnswer((_) async => http.Response(ipinfoJson, 200));

      final result1 = await service.getIPInfo();
      final result2 = await service.getIPInfo();
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      // Should only call the endpoint once due to cache
      verify(mockClient.get(Uri.parse('https://ipinfo.io/json'))).called(1);
    });
  });
}
