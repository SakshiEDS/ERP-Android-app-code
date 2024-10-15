// lib/services/api_gateway.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart'; // Import the Config class with the base URL

class ApiGateway {
  static final ApiGateway _instance = ApiGateway._internal();

  // Create a factory constructor for singleton pattern
  factory ApiGateway() {
    return _instance;
  }

  ApiGateway._internal();

  // POST request method
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    final url = Uri.parse('${Config.BASE_URL}$endpoint');

    // Add Authorization token if available
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    return response;
  }

  // GET request method
  Future<http.Response> getRequest(String endpoint, String token) async {
    final url = Uri.parse('${Config.BASE_URL}$endpoint');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token', // Include the token
        'Content-Type': 'application/json',
      },
    );
    return response;
  }
}
