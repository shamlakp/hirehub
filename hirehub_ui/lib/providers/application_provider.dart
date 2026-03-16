import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/job_application.dart';

class ApplicationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<JobApplication> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getApplications();
      final List<dynamic> data = response.data;
      _applications = data.map((json) => JobApplication.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load applications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    _isLoading = true;
    notifyListeners();

    try {
      // We'll need to add updateApplicationStatus to ApiService as well
      await _apiService.updateApplicationStatus(applicationId, status);
      
      // Update local state
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        final oldApp = _applications[index];
        _applications[index] = JobApplication(
          id: oldApp.id,
          jobId: oldApp.jobId,
          jobPosition: oldApp.jobPosition,
          companyName: oldApp.companyName,
          applicantName: oldApp.applicantName,
          status: status,
          appliedAt: oldApp.appliedAt,
          notes: oldApp.notes,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update status: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
