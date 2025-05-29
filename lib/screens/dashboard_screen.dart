import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/device_status.dart';
import '../services/diagnostics_service.dart';
import '../services/ios_diagnostics_service.dart';
import '../services/log_storage_service.dart';
import '../models/log_entry.dart';
import '../widgets/diagnostics_notice.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _diagnosticsService = DiagnosticsService();
  final _iosDiagnosticsService = IOSDiagnosticsService();
  final _logStorageService = LogStorageService();
  DeviceStatus? _currentStatus;
  Map<String, dynamic>? _iosDiagnostics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _logStorageService.init();
    await _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
        final iosDiagnostics = await _iosDiagnosticsService
            .collectDiagnostics();
        setState(() => _iosDiagnostics = iosDiagnostics);
      } else {
        final status = await _diagnosticsService.performDiagnostics();
        final summary = _diagnosticsService.generateSummary(status);

        final logEntry = LogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          deviceStatus: status,
          testResults: {
            'airplaneMode': status.isAirplaneMode,
            'simInserted': status.isSimInserted,
            'mobileDataEnabled': status.isMobileDataEnabled,
            'dnsResolution': status.canResolveDns,
            'publicIpReachable': status.canReachPublicIp,
          },
          summary: summary,
        );

        await _logStorageService.saveLog(logEntry);
        setState(() => _currentStatus = status);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error running diagnostics: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to log history screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const DiagnosticsNotice(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Platform.isIOS
                ? _buildIOSDiagnosticsView()
                : _currentStatus == null
                ? const Center(child: Text('No diagnostic data available'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildConnectivityCard(),
                        const SizedBox(height: 16),
                        _buildDiagnosticsCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runDiagnostics,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildIOSDiagnosticsView() {
    if (_iosDiagnostics == null) {
      return const Center(child: Text('No diagnostic data available'));
    }
    final device = _iosDiagnostics!['device'] as Map?;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'iOS Diagnostics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFriendlyRow(
                'Connection',
                _iosDiagnostics!['connectivity'],
                'How this device is currently connected to the internet.',
              ),
              _buildFriendlyRow(
                'Carrier',
                _iosDiagnostics!['carrier'],
                'SIM/network provider (if available).',
              ),
              const Divider(),
              const Text(
                'Device Info',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              _buildFriendlyRow('Model', device?['model'], ''),
              _buildFriendlyRow('iOS Version', device?['systemVersion'], ''),
              _buildFriendlyRow('Device Name', device?['name'], ''),
              const Divider(),
              _buildFriendlyRow(
                'DNS Resolution',
                _iosDiagnostics!['dnsResolution'] == true
                    ? 'Working'
                    : 'Failed',
                'Can the device resolve domain names?',
              ),
              _buildFriendlyRow('Timestamp', _iosDiagnostics!['timestamp'], ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendlyRow(String label, dynamic value, String help) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    (value == null ||
                            value.toString().isEmpty ||
                            value == 'Unavailable' ||
                            value == '--')
                        ? 'Not available'
                        : value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
                if (help.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                    padding: const EdgeInsets.only(left: 4.0),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(help),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    tooltip: 'More info',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SIM Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusRow('ICCID', _currentStatus?.iccid ?? 'N/A'),
            _buildStatusRow('IMSI', _currentStatus?.imsi ?? 'N/A'),
            _buildStatusRow('Carrier', _currentStatus?.carrierName ?? 'N/A'),
            _buildStatusRow('Country', _currentStatus?.countryCode ?? 'N/A'),
            _buildStatusRow(
              'Data Roaming',
              (_currentStatus?.isDataRoaming ?? false) ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connectivity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Connection Type',
              _currentStatus?.connectionType ?? 'N/A',
            ),
            _buildStatusRow(
              'Signal Strength',
              _currentStatus?.signalStrength?.toString() ?? 'N/A',
            ),
            _buildStatusRow('IP Address', _currentStatus?.ipAddress ?? 'N/A'),
            _buildStatusRow(
              'Mobile Data',
              (_currentStatus?.isMobileDataEnabled ?? false)
                  ? 'Enabled'
                  : 'Disabled',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnostics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDiagnosticRow(
              'Airplane Mode',
              _currentStatus?.isAirplaneMode ?? false,
            ),
            _buildDiagnosticRow(
              'SIM Inserted',
              _currentStatus?.isSimInserted ?? false,
            ),
            _buildDiagnosticRow(
              'DNS Resolution',
              _currentStatus?.canResolveDns ?? false,
            ),
            _buildDiagnosticRow(
              'Public IP Reachable',
              _currentStatus?.canReachPublicIp ?? false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, bool isPassing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isPassing ? Icons.check_circle : Icons.error,
            color: isPassing ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
