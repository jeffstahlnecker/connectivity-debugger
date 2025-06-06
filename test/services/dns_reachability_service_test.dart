import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:io';
import 'dart:async';

import 'dns_reachability_service_test.mocks.dart';
import 'package:connectivity_debugger/services/dns_reachability_service.dart';
import 'package:connectivity_debugger/models/dns_check_result.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<InternetAddress>(as: #MockInternetAddress),
    MockSpec<Socket>(as: #MockSocket),
  ],
)
void main() {
  late DnsReachabilityService service;
  late MockInternetAddress mockAddress;
  late MockSocket mockSocket;

  setUp(() {
    mockAddress = MockInternetAddress();
    mockSocket = MockSocket();
  });

  group('DnsReachabilityService', () {
    test('returns success for DNS resolution', () async {
      service = DnsReachabilityService(lookup: (host) async => [mockAddress]);
      final result = await service.checkDns('google.com');
      expect(result.success, isTrue);
      expect(result.type, CheckType.dns);
      expect(result.target, 'google.com');
      expect(result.error, isNull);
    });

    test('returns failure for DNS resolution error', () async {
      service = DnsReachabilityService(
        lookup: (host) async => throw SocketException('Failed'),
      );
      final result = await service.checkDns('bad.domain');
      expect(result.success, isFalse);
      expect(result.type, CheckType.dns);
      expect(result.target, 'bad.domain');
      expect(result.error, contains('Failed'));
    });

    test('returns success for reachability check', () async {
      when(mockSocket.close()).thenAnswer((_) async => null);
      service = DnsReachabilityService(
        connect: (host, port, {timeout}) async => mockSocket,
      );
      final result = await service.checkReachability('8.8.8.8', 53);
      expect(result.success, isTrue);
      expect(result.type, CheckType.reachability);
      expect(result.target, '8.8.8.8:53');
      expect(result.error, isNull);
    });

    test('returns failure for reachability check error', () async {
      service = DnsReachabilityService(
        connect: (host, port, {timeout}) async =>
            throw SocketException('No route'),
      );
      final result = await service.checkReachability('1.1.1.1', 53);
      expect(result.success, isFalse);
      expect(result.type, CheckType.reachability);
      expect(result.target, '1.1.1.1:53');
      expect(result.error, contains('No route'));
    });

    test('handles unexpected errors gracefully', () async {
      service = DnsReachabilityService(
        lookup: (host) async => throw Exception('Unexpected'),
      );
      final result = await service.checkDns('error.com');
      expect(result.success, isFalse);
      expect(result.error, contains('Unexpected'));
    });
  });
}
