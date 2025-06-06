import 'dart:async';
import 'dart:io';
import 'package:connectivity_debugger/models/dns_check_result.dart';

class DnsReachabilityService {
  final Duration cacheDuration;
  final Future<List<InternetAddress>> Function(String)? lookup;
  final Future<Socket> Function(String, int, {Duration? timeout})? connect;

  final Map<String, _DnsCacheEntry> _dnsCache = {};

  DnsReachabilityService({
    this.cacheDuration = const Duration(minutes: 5),
    this.lookup,
    this.connect,
  });

  Future<bool> canResolveDns(String host) async {
    final now = DateTime.now();
    final cacheEntry = _dnsCache[host];
    if (cacheEntry != null &&
        now.difference(cacheEntry.fetchedAt) < cacheDuration) {
      return cacheEntry.result;
    }
    try {
      final lookupFn = lookup ?? InternetAddress.lookup;
      final addresses = await lookupFn(host);
      final result = addresses.isNotEmpty;
      _dnsCache[host] = _DnsCacheEntry(result, now);
      return result;
    } catch (_) {
      _dnsCache[host] = _DnsCacheEntry(false, now);
      return false;
    }
  }

  Future<bool> canReachHost(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final connectFn = connect ?? Socket.connect;
      final socket = await connectFn(host, port, timeout: timeout);
      await socket.close();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<DnsCheckResult> checkDns(String domain) async {
    final lookupFn = lookup ?? InternetAddress.lookup;
    final start = DateTime.now();
    try {
      final addresses = await lookupFn(domain);
      final latency = DateTime.now().difference(start).inMilliseconds;
      return DnsCheckResult(
        target: domain,
        success: addresses.isNotEmpty,
        latencyMs: latency,
        error: null,
        type: CheckType.dns,
      );
    } on SocketException catch (e) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      return DnsCheckResult(
        target: domain,
        success: false,
        latencyMs: latency,
        error: e.message,
        type: CheckType.dns,
      );
    } catch (e) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      return DnsCheckResult(
        target: domain,
        success: false,
        latencyMs: latency,
        error: e.toString(),
        type: CheckType.dns,
      );
    }
  }

  Future<DnsCheckResult> checkReachability(String host, int port) async {
    final connectFn = connect ?? Socket.connect;
    final start = DateTime.now();
    final target = '$host:$port';
    try {
      final socket = await connectFn(host, port, timeout: Duration(seconds: 5));
      final latency = DateTime.now().difference(start).inMilliseconds;
      await socket.close();
      return DnsCheckResult(
        target: target,
        success: true,
        latencyMs: latency,
        error: null,
        type: CheckType.reachability,
      );
    } on SocketException catch (e) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      return DnsCheckResult(
        target: target,
        success: false,
        latencyMs: latency,
        error: e.message,
        type: CheckType.reachability,
      );
    } catch (e) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      return DnsCheckResult(
        target: target,
        success: false,
        latencyMs: latency,
        error: e.toString(),
        type: CheckType.reachability,
      );
    }
  }
}

class _DnsCacheEntry {
  final bool result;
  final DateTime fetchedAt;
  _DnsCacheEntry(this.result, this.fetchedAt);
}
