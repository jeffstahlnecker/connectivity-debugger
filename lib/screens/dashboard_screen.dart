import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/device_status.dart';
import '../services/diagnostics_service.dart';
import '../services/ios_diagnostics_service.dart';
import '../services/log_storage_service.dart';
import '../models/log_entry.dart';
import '../widgets/diagnostics_notice.dart';
import '../screens/log_history_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ip_lookup_service.dart';
import '../services/dns_reachability_service.dart';
import '../services/speed_test_service.dart';
import 'results_screen.dart';
import 'dart:io' show NetworkInterface, InternetAddressType;
import 'package:meta/meta.dart';
import '../services/settings_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final LogStorageService? logStorageService;
  final IOSDiagnosticsService? iosDiagnosticsService;
  const DashboardScreen({
    super.key,
    this.logStorageService,
    this.iosDiagnosticsService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _diagnosticsService = DiagnosticsService();
  late final IOSDiagnosticsService _iosDiagnosticsService;
  late final LogStorageService _logStorageService;
  DeviceStatus? _currentStatus;
  Map<String, dynamic>? _iosDiagnostics;
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosticsResult;
  DeviceStatus? _quickStatus;
  String? _diagnosticsEmail;

  @override
  void initState() {
    super.initState();
    _logStorageService = widget.logStorageService ?? LogStorageService();
    _iosDiagnosticsService =
        widget.iosDiagnosticsService ?? IOSDiagnosticsService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _fetchQuickStatus();
      _loadDiagnosticsEmail();
    });
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
        if (!mounted) return;
        setState(() => _iosDiagnostics = iosDiagnostics);
        // Save log for iOS
        final logEntry = LogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          deviceStatus: DeviceStatus(
            connectionType: iosDiagnostics['connectivity']?.toString(),
            carrierName: iosDiagnostics['carrier']?.toString(),
            countryCode: null,
            isDataRoaming: false,
            isAirplaneMode: false,
            isSimInserted: false,
            isMobileDataEnabled: false,
            ipAddress: null,
            canResolveDns: iosDiagnostics['dnsResolution'] == true,
            canReachPublicIp: false,
            timestamp: iosDiagnostics['timestamp'] != null
                ? DateTime.tryParse(iosDiagnostics['timestamp']) ??
                      DateTime.now()
                : DateTime.now(),
          ),
          testResults: iosDiagnostics,
          summary: 'iOS diagnostics',
        );
        await _logStorageService.saveLog(logEntry);
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
        if (!mounted) return;
        setState(() => _currentStatus = status);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error running diagnostics: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runAllDiagnostics() async {
    setState(() => _isLoading = true);
    final Map<String, dynamic> results = {};
    final List<String> errors = [];
    try {
      // Device Status
      print('Starting performDiagnostics');
      try {
        results['deviceStatus'] = await _diagnosticsService
            .performDiagnostics()
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        errors.add('Device status: $e');
      }

      // IP Lookup
      print('Starting getIPInfo');
      try {
        results['ipLookup'] = await IPLookupService().getIPInfo().timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        errors.add('IP lookup: $e');
      }

      // DNS
      print('Starting checkDns');
      try {
        results['dns'] = await DnsReachabilityService()
            .checkDns('google.com')
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        errors.add('DNS: $e');
      }

      // Reachability
      print('Starting checkReachability');
      try {
        results['reach'] = await DnsReachabilityService()
            .checkReachability('8.8.8.8', 53)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        errors.add('Reachability: $e');
      }

      // Speed Test
      print('Starting runSpeedTest');
      try {
        results['speedTest'] = await SpeedTestService().runSpeedTest().timeout(
          const Duration(seconds: 30),
        );
      } catch (e) {
        errors.add('Speed test: $e');
      }

      print('Diagnostics complete');
      _diagnosticsResult = results;
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diagnostics completed with errors:\n${errors.join('\n')}',
            ),
          ),
        );
      }
    } catch (e, stack) {
      print('Diagnostics error: $e');
      print(stack);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Diagnostics failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchQuickStatus() async {
    try {
      var status = await _diagnosticsService.performDiagnostics();
      // Improve IP address fetching for iOS
      String? ipAddress = status.ipAddress;
      if (Platform.isIOS && (ipAddress == null || ipAddress == '')) {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        for (var interface in interfaces) {
          if (interface.name == 'en0' || interface.name == 'pdp_ip0') {
            ipAddress = interface.addresses.isNotEmpty
                ? interface.addresses.first.address
                : null;
            break;
          }
        }
        status = status.copyWith(ipAddress: ipAddress);
      }
      setState(() {
        _quickStatus = status;
      });
    } catch (_) {}
  }

  Future<void> _loadDiagnosticsEmail() async {
    final settingsService = SettingsService();
    final settings = await settingsService.loadSettings();
    setState(() {
      _diagnosticsEmail = settings.diagnosticsEmail;
    });
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (result is String) {
      setState(() {
        _diagnosticsEmail = result;
      });
    }
  }

  void _shareDiagnostics() {
    if (_diagnosticsResult == null) return;
    final text = _formatDiagnosticsForShare(_diagnosticsResult!);
    Share.share(text, subject: 'Connectivity Diagnostics Results');
  }

  String _formatDiagnosticsForShare(Map<String, dynamic> result) {
    // Format all diagnostics info into a readable string
    final deviceStatus = result['deviceStatus'];
    final ipLookup = result['ipLookup'];
    final dns = result['dns'];
    final reach = result['reach'];
    final speedTest = result['speedTest'];
    return [
      'Device Status:',
      deviceStatus.toString(),
      '',
      'IP Lookup:',
      ipLookup.toString(),
      '',
      'DNS:',
      dns.toString(),
      '',
      'Reachability:',
      reach.toString(),
      '',
      'Speed Test:',
      speedTest.toString(),
    ].join('\n');
  }

  void _sendDiagnosticsEmail() async {
    if (_diagnosticsResult == null ||
        _diagnosticsEmail == null ||
        _diagnosticsEmail!.isEmpty)
      return;
    final text = _formatDiagnosticsForShare(_diagnosticsResult!);
    final uri = Uri(
      scheme: 'mailto',
      path: _diagnosticsEmail,
      queryParameters: {
        'subject': 'Connectivity Diagnostics Results',
        'body': text,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email app found to send diagnostics.'),
        ),
      );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LogHistoryScreen(logStorageService: _logStorageService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          const DiagnosticsNotice(),
          if (_quickStatus != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_quickStatus!.connectionType != null)
                    Card(
                      child: ListTile(
                        title: const Text('Connection Type'),
                        subtitle: Text(_quickStatus!.connectionType!),
                      ),
                    ),
                  if (!Platform.isIOS && _quickStatus!.carrierName != null)
                    Card(
                      child: ListTile(
                        title: const Text('Carrier'),
                        subtitle: Text(_quickStatus!.carrierName!),
                      ),
                    ),
                  if (_quickStatus!.ipAddress != null &&
                      _quickStatus!.ipAddress != 'Unknown')
                    Card(
                      child: ListTile(
                        title: const Text('IP Address'),
                        subtitle: Text(_quickStatus!.ipAddress!),
                      ),
                    ),
                  if (_quickStatus!.isMobileDataEnabled != null)
                    Card(
                      child: ListTile(
                        title: const Text('Mobile Data'),
                        subtitle: Text(
                          _quickStatus!.isMobileDataEnabled
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _diagnosticsResult == null
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(220, 60),
                        textStyle: const TextStyle(fontSize: 22),
                      ),
                      onPressed: _runAllDiagnostics,
                      child: const Text('Run Diagnostics'),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(
                            _diagnosticsEmail != null &&
                                    _diagnosticsEmail!.isNotEmpty
                                ? Icons.send
                                : Icons.share,
                          ),
                          label: Text(
                            _diagnosticsEmail != null &&
                                    _diagnosticsEmail!.isNotEmpty
                                ? 'Send Results'
                                : 'Share Results',
                          ),
                          onPressed:
                              _diagnosticsEmail != null &&
                                  _diagnosticsEmail!.isNotEmpty
                              ? _sendDiagnosticsEmail
                              : _shareDiagnostics,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(220, 60),
                            textStyle: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Results'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultsScreen(
                                  diagnosticsResult: _diagnosticsResult!,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(220, 60),
                            textStyle: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Rerun Diagnostics'),
                          onPressed: () {
                            setState(() {
                              _diagnosticsResult = null;
                            });
                            _runAllDiagnostics();
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(220, 60),
                            textStyle: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
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

  @visibleForTesting
  void setDiagnosticsResultForTest(Map<String, dynamic> result) {
    setState(() {
      _diagnosticsResult = result;
      _isLoading = false;
    });
  }

  @visibleForTesting
  Future<void> runDiagnosticsForTest() => _runDiagnostics();

  @visibleForTesting
  void setDiagnosticsEmailForTest(String email) {
    setState(() {
      _diagnosticsEmail = email;
    });
  }
}
