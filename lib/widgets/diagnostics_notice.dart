import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class DiagnosticsNotice extends StatelessWidget {
  const DiagnosticsNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Note: Due to iOS system restrictions, only basic connectivity and device info can be collected. SIM and cellular diagnostics are not available.',
          style: TextStyle(color: Colors.orange, fontSize: 14),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
