import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  static const _diagnosticsEmailKey = 'diagnostics_email';

  Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_diagnosticsEmailKey);
    return Settings(diagnosticsEmail: email);
  }

  Future<void> saveDiagnosticsEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.isEmpty) {
      await prefs.remove(_diagnosticsEmailKey);
    } else {
      await prefs.setString(_diagnosticsEmailKey, email);
    }
  }
}
