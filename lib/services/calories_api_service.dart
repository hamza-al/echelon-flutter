import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CaloriesApiService {
  static const String baseUrl = 'https://echelon-fastapi.fly.dev/chat';
  final AuthService _authService;

  CaloriesApiService(this._authService);

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = _authService.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<CaloriesResponse> getCalories({
    required String quantity,
    required String foodItem,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calories'),
        headers: _getHeaders(),
        body: json.encode({
          'quantity': quantity,
          'food_item': foodItem,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CaloriesResponse.fromJson(data);
      } else {
        throw Exception('Failed to get calories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calling calories API: $e');
    }
  }
}

class CaloriesResponse {
  final String itemName;
  final double calories;
  final Macros macros;

  CaloriesResponse({
    required this.itemName,
    required this.calories,
    required this.macros,
  });

  factory CaloriesResponse.fromJson(Map<String, dynamic> json) {
    return CaloriesResponse(
      itemName: json['item_name'] as String,
      calories: (json['calories'] as num).toDouble(),
      macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
    );
  }
}

class Macros {
  final double protein;
  final double carbs;
  final double fats;

  Macros({
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
    );
  }
}
