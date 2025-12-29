import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/auth_data.dart';

class AuthService {
  static const String _authBoxName = 'auth';
  static const String _authKey = 'auth_data';
  static const String _baseUrl = 'https://echelon-fastapi.fly.dev';
  
  Box<AuthData>? _authBox;
  AuthData? _currentAuth;

  // Initialize service
  Future<void> initialize() async {
    _authBox = await Hive.openBox<AuthData>(_authBoxName);
    _currentAuth = _authBox?.get(_authKey);
    
    // If no auth data exists, create new device ID
    if (_currentAuth == null) {
      await _createNewDevice();
    }
    
    // If no JWT token, register device
    if (_currentAuth?.jwtToken == null) {
      await register();
    }
  }

  // Create new device with UUID
  Future<void> _createNewDevice() async {
    const uuid = Uuid();
    final deviceId = uuid.v4();
    
    _currentAuth = AuthData(deviceId: deviceId);
    await _authBox?.put(_authKey, _currentAuth!);
  }

  // Register device and get JWT
  Future<bool> register() async {
    if (_currentAuth == null) {
      await _createNewDevice();
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'device_id': _currentAuth!.deviceId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _currentAuth!.jwtToken = data['access_token']; // Backend returns 'access_token'
        
        // Store token expiry if provided (optional)
        if (data['expires_at'] != null) {
          _currentAuth!.tokenExpiry = DateTime.parse(data['expires_at']);
        }
        
        await _currentAuth!.save();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get current JWT token
  String? get token => _currentAuth?.jwtToken;

  // Get device ID
  String? get deviceId => _currentAuth?.deviceId;

  // Check if authenticated
  bool get isAuthenticated => _currentAuth?.jwtToken != null;

  // Handle 401 error by re-registering
  Future<bool> handleUnauthorized() async {
    return await register();
  }

  // Clear auth data (for testing/logout)
  Future<void> clearAuth() async {
    _currentAuth?.jwtToken = null;
    _currentAuth?.tokenExpiry = null;
    await _currentAuth?.save();
  }

  // Reset completely (new device)
  Future<void> reset() async {
    await _authBox?.clear();
    await _createNewDevice();
    await register();
  }
}

