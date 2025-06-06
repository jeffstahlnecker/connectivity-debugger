import 'package:flutter/material.dart';
import '../services/log_storage_service.dart';
import '../models/log_entry.dart';
import 'package:intl/intl.dart';

class LogHistoryScreen extends StatefulWidget {
  final LogStorageService logStorageService;
  const LogHistoryScreen({Key? key, required this.logStorageService})
    : super(key: key);

  @override
  State<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends State<LogHistoryScreen> {
  late Future<List<LogEntry>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = widget.logStorageService.getAllLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log History')),
      body: FutureBuilder<List<LogEntry>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No logs found.'));
          }
          final logs = snapshot.data!;
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(
                  log.summary.isNotEmpty ? log.summary : 'No summary',
                ),
                subtitle: Text(DateFormat.yMd().add_jm().format(log.timestamp)),
                onTap: () {
                  // Optionally show log details
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Log Details'),
                      content: SingleChildScrollView(
                        child: Text(log.toJson().toString()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
