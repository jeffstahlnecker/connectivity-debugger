import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import '../models/speed_test_result.dart';

class SpeedTestService {
  final FlutterInternetSpeedTest _speedTest = FlutterInternetSpeedTest();

  Future<SpeedTestResult> runSpeedTest() async {
    final completer = Completer<SpeedTestResult>();
    double? downloadMbps;
    double? uploadMbps;
    DateTime timestamp = DateTime.now();

    try {
      _speedTest.startTesting(
        onCompleted: (download, upload) {
          downloadMbps = download.transferRate;
          uploadMbps = upload.transferRate;
          completer.complete(
            SpeedTestResult(
              downloadMbps: downloadMbps ?? 0.0,
              uploadMbps: uploadMbps ?? 0.0,
              server: 'HTTP Speed Test',
              timestamp: timestamp,
            ),
          );
        },
        onError: (String errorMessage, String speedTestError) {
          completer.completeError(
            Exception('Speed test failed: $errorMessage'),
          );
        },
        onDownloadComplete: (download) {
          downloadMbps = download.transferRate;
        },
        onUploadComplete: (upload) {
          uploadMbps = upload.transferRate;
        },
        onProgress: (double percent, TestResult dataTransfer) {
          // Optional: Add progress tracking if needed
        },
      );

      // Add timeout to prevent hanging
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Speed test timed out after 30 seconds'),
          );
        }
      });

      return completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    }
  }
}
