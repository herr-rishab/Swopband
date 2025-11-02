import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class NfcVisibilityService {
  static const String _endpoint =
      'https://s6wui23dr2wfl2jppucvmxqfna0jcefc.lambda-url.us-east-1.on.aws/';

  static bool? _cachedResult;

  static Future<bool> shouldShowNfcConnectStep() async {
    if (_cachedResult != null) {
      return _cachedResult!;
    }

    try {
      final response = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['result'] is bool) {
          _cachedResult = decoded['result'] as bool;
          return _cachedResult!;
        }
        log('Unexpected response shape from NFC visibility endpoint: ${response.body}');
      } else {
        log('Failed to fetch NFC visibility: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e, stackTrace) {
      log('Error requesting NFC visibility: $e', stackTrace: stackTrace);
    }

    _cachedResult = true;
    return _cachedResult!;
  }

  static void resetCache() {
    _cachedResult = null;
  }
}
