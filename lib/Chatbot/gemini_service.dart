import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  static const String _apiKey = 'AIzaSyCf5N56Qj-FyaCwCXggjKnUQRcRdgWExZk';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  static Future<String> getReply(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['candidates'][0]['content']['parts'][0]['text'];
    } else {
      return 'Error: ${response.statusCode}';
    }
  }
}
