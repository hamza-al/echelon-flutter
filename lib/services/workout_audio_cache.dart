import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';

class WorkoutAudioCache {
  static const String _cacheFileName = 'workout_start_greeting.mp3';
  
  final AuthService _authService;
  
  WorkoutAudioCache(this._authService);
  
  /// Get the cached audio file path
  Future<String> _getCachePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_cacheFileName';
  }
  
  /// Check if cached audio exists and is valid
  Future<bool> hasCachedAudio() async {
    try {
      final cachePath = await _getCachePath();
      final file = File(cachePath);
      
      if (!await file.exists()) {
        return false;
      }
      
      // Check if file is not empty
      final length = await file.length();
      if (length == 0) {
        return false;
      }
      
      // Could add version checking here if needed
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Fetch and cache the workout start greeting audio
  Future<void> fetchAndCacheAudio() async {
    try {
      final headers = <String, String>{};
      final token = _authService.token;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('https://echelon-fastapi.fly.dev/chat/start_workout_voice'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final base64Audio = body['audio']['base64'] as String;
        
        // Decode base64 to bytes
        final audioBytes = base64Decode(base64Audio);
        
        // Save to cache
        final cachePath = await _getCachePath();
        final file = File(cachePath);
        await file.writeAsBytes(audioBytes);
      }
    } catch (e) {
      // Silently fail - we'll just fetch on demand if cache fails
    }
  }
  
  /// Get the cached audio file path (returns null if not cached)
  Future<String?> getCachedAudioPath() async {
    if (await hasCachedAudio()) {
      return await _getCachePath();
    }
    return null;
  }
  
  /// Clear the audio cache
  Future<void> clearCache() async {
    try {
      final cachePath = await _getCachePath();
      final file = File(cachePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }
}

