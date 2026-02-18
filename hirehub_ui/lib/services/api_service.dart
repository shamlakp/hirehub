import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  late final Dio _dio;
  String? _token;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for others (Web/Desktop)
        baseUrl: getBaseUrl(),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // Add interceptor to include token in requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kDebugMode) {
            debugPrint('API Request: ${options.method} ${options.path}');
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Token $_token';
            if (kDebugMode) {
              debugPrint(
                'Authorization header set with token: ${_token!.substring(0, 4)}...',
              );
            }
          } else {
            if (kDebugMode) {
              debugPrint('No token found in ApiService');
            }
          }
          return handler.next(options);
        },

        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              'API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
            );
            debugPrint('Error data: ${error.response?.data}');
            debugPrint('Error message: ${error.message}');
            debugPrint('Error type: ${error.type}');
            debugPrint('Underlying error: ${error.error}');
          }
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Load token from secure storage on initialization
  Future<void> loadToken() async {
    try {
      // Primary: secure storage
      _token = await _secureStorage.read(key: _tokenKey);
      // Fallback: shared preferences (legacy)
      if (_token == null) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(_tokenKey);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Save token to secure storage (and shared prefs for backward compatibility)
  Future<void> saveToken(String token) async {
    try {
      _token = token;
      await _secureStorage.write(key: _tokenKey, value: token);
      // Keep a non-sensitive copy in prefs if other parts rely on it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      // Handle error
    }
  }

  /// Clear token and user data
  Future<void> clearToken() async {
    try {
      _token = null;
      await _secureStorage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      // Handle error
    }
  }

  /// Get current token
  String? getToken() => _token;

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(userData);
      await prefs.setString(_userKey, json);
    } catch (e) {
      // Handle error
    }
  }

  /// Load user data (returns null if not present or invalid)
  Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userKey);
      if (jsonString == null) return null;
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      return null;
    }
  }

  Future<Response> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/adminpanel/api/login/',
        data: {'username': username, 'password': password},
      );

      // Extract token from response if available
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('token')) {
          await saveToken(data['token']);
        }
        // Save user data
        await saveUserData(data);
      }

      return response;
    } catch (e) {
      _logError('Login', e);
      rethrow;
    }
  }

  Future<Response> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/adminpanel/api/register/', data: data);
      return response;
    } catch (e) {
      _logError('Register', e);
      rethrow;
    }
  }

  Future<Response> registerApplicant(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/applicant/register/', data: data);
      return response;
    } catch (e) {
      _logError('RegisterApplicant', e);
      rethrow;
    }
  }

  Future<Response> getJobs() async {
    try {
      final response = await _dio.get('/api/jobs/');
      return response;
    } catch (e) {
      _logError('getJobs', e);
      rethrow;
    }
  }

  Future<Response> getPlatformSettings() async {
    return await _dio.get('/adminpanel/api/platform-settings/');
  }

  Future<Response> createJobPost(FormData formData) async {
    return await _dio.post('/api/jobs/', data: formData);
  }

  Future<Response> getApplicantProfile() async {
    try {
      final response = await _dio.get('/api/applicant/profile/');
      return response;
    } catch (e) {
      _logError('getApplicantProfile', e);
      rethrow;
    }
  }

  Future<Response> updateApplicantProfile(
    Map<String, dynamic> data, [
    String? resumePath,
  ]) async {
    try {
      final formData = FormData();
      data.forEach((k, v) {
        formData.fields.add(MapEntry(k, v.toString()));
      });
      if (resumePath != null) {
        formData.files.add(
          MapEntry(
            'resume',
            await MultipartFile.fromFile(
              resumePath,
              filename: resumePath.split('/').last,
            ),
          ),
        );
      }
      final response = await _dio.patch(
        '/api/applicant/profile/',
        data: formData,
      );
      return response;
    } catch (e) {
      _logError('updateApplicantProfile', e);
      rethrow;
    }
  }

  Future<Response> getRecruiterProfile() async {
    try {
      final response = await _dio.get('/api/recruiter/profile/');
      return response;
    } catch (e) {
      _logError('getRecruiterProfile', e);
      rethrow;
    }
  }

  Future<Response> updateRecruiterProfile(
    Map<String, dynamic> data, [
    PlatformFile? logoFile,
  ]) async {
    try {
      final formData = FormData();
      data.forEach((k, v) {
        formData.fields.add(MapEntry(k, v.toString()));
      });
      if (logoFile != null) {
        if (kIsWeb) {
             if (logoFile.bytes != null) {
                formData.files.add(
                  MapEntry(
                    'logo',
                    MultipartFile.fromBytes(
                      logoFile.bytes!,
                      filename: logoFile.name,
                    ),
                  ),
                );
             }
        } else {
             if (logoFile.path != null) {
                formData.files.add(
                  MapEntry(
                    'logo',
                    await MultipartFile.fromFile(
                      logoFile.path!,
                      filename: logoFile.name,
                    ),
                  ),
                );
             }
        }
      }
      final response = await _dio.patch(
        '/api/recruiter/profile/',
        data: formData,
      );
      return response;
    } catch (e) {
      _logError('updateRecruiterProfile', e);
      rethrow;
    }
  }

  static String getBaseUrl() {
    if (kIsWeb) {
      if (kDebugMode) return 'http://localhost:8000';
      return 'https://shamlashammu.pythonanywhere.com';
    }
    if (defaultTargetPlatform == TargetPlatform.android && kDebugMode) {
      return 'http://10.0.2.2:8000';
    }
    if (kDebugMode) return 'http://127.0.0.1:8000';
    return 'https://shamlashammu.pythonanywhere.com';
  }

  void _logError(String context, dynamic error) {
    print('API Error [$context]: $error');
    if (error is DioException) {
      print('Status: ${error.response?.statusCode}');
      print('Data: ${error.response?.data}');
      print('Message: ${error.message}');
    }
  }
}
