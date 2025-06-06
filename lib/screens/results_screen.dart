import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> diagnosticsResult;
  const ResultsScreen({Key? key, required this.diagnosticsResult})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final text = _formatDiagnosticsForShare(diagnosticsResult);
              Share.share(text, subject: 'Connectivity Diagnostics Results');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(_formatDiagnosticsForDisplay(diagnosticsResult)),
        ),
      ),
    );
  }

  String _formatDiagnosticsForDisplay(Map<String, dynamic> result) {
    final deviceStatus = result['deviceStatus'];
    final ipLookup = result['ipLookup'];
    final dns = result['dns'];
    final reach = result['reach'];
    final speedTest = result['speedTest'];
    return [
      'Device Status:',
      deviceStatus != null ? _prettyJson(deviceStatus.toJson()) : 'N/A',
      '',
      'IP Lookup:',
      ipLookup != null ? _prettyJson(ipLookup.toJson()) : 'N/A',
      '',
      'DNS:',
      dns != null ? _prettyJson(dns.toJson()) : 'N/A',
      '',
      'Reachability:',
      reach != null ? _prettyJson(reach.toJson()) : 'N/A',
      '',
      'Speed Test:',
      speedTest != null ? _prettyJson(speedTest.toJson()) : 'N/A',
    ].join('\n');
  }

  String _formatDiagnosticsForShare(Map<String, dynamic> result) {
    final all = {
      'deviceStatus': result['deviceStatus']?.toJson(),
      'ipLookup': result['ipLookup']?.toJson(),
      'dns': result['dns']?.toJson(),
      'reach': result['reach']?.toJson(),
      'speedTest': result['speedTest']?.toJson(),
    };
    return JsonEncoder.withIndent('  ').convert(all);
  }

  String _prettyJson(Map<String, dynamic> json) {
    return JsonEncoder.withIndent('  ').convert(json);
  }
}
