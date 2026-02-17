import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/platform_settings.dart';

class PlatformProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  PlatformSettings? _settings;
  bool _isLoading = false;

  PlatformSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getPlatformSettings();
      if (response.statusCode == 200) {
        _settings = PlatformSettings.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Error fetching platform settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
