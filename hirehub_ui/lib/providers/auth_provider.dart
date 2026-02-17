import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  /// Initialize auth on app startup - load token if exists
  Future<void> initializeAuth() async {
    try {
      await _apiService.loadToken();
      if (_apiService.getToken() != null) {
        // load persisted user data if available
        final stored = await _apiService.loadUserData();
        if (stored != null) {
          _userData = stored;
        }
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _userData = data;
        if (data.containsKey('token')) {
          await _apiService.saveToken(data['token']);
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Login failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleError(e);
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user - clear token and user data
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.clearToken();
      _isAuthenticated = false;
      _userData = null;
      _errorMessage = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register recruiter via API
  Future<bool> registerRecruiter(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(data);
      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _errorMessage = 'Registration failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  /// Register applicant via API
  Future<bool> registerApplicant(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.registerApplicant(data);
      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _errorMessage = 'Registration failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  /// Fetch applicant profile
  Future<Map<String, dynamic>?> fetchApplicantProfile() async {
    try {
      final response = await _apiService.getApplicantProfile();
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return null;
  }

  /// Update applicant profile (optionally with resume path)
  Future<bool> updateApplicantProfile(
    Map<String, dynamic> data, [
    String? resumePath,
  ]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.updateApplicantProfile(
        data,
        resumePath,
      );
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _errorMessage = 'Update failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  /// Fetch recruiter profile
  Future<Map<String, dynamic>?> fetchRecruiterProfile() async {
    try {
      final response = await _apiService.getRecruiterProfile();
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return null;
  }

  /// Update recruiter profile
  Future<bool> updateRecruiterProfile(
    Map<String, dynamic> data, [
    PlatformFile? logoFile,
  ]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.updateRecruiterProfile(
        data,
        logoFile,
      );
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _errorMessage = 'Update failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data != null) {
        if (data is Map) {
          if (data.containsKey('error')) return data['error'].toString();
          if (data.containsKey('detail')) return data['detail'].toString();

          // Collect validation errors
          final List<String> errorMessages = [];
          data.forEach((key, value) {
            String msg = '';
            if (value is List) {
              msg = value.join(", ");
            } else {
              msg = value.toString();
            }
            // Capitalize key for readability
            final keyName = key.substring(0, 1).toUpperCase() + key.substring(1);
            errorMessages.add('$keyName: $msg');
          });

          if (errorMessages.isNotEmpty) {
            return errorMessages.join('\n');
          }
        }
        return 'Request failed: $data';
      }
      return error.message ?? 'Unknown connection error';
    }
    return error.toString();
  }
}
