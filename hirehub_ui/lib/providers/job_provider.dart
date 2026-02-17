import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/job_post.dart';

class JobProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<JobPost> _jobs = [];
  List<JobPost> _filteredJobs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchKeyword = '';
  String _searchLocation = '';

  List<JobPost> get jobs => _filteredJobs.isEmpty && _searchKeyword.isEmpty && _searchLocation.isEmpty 
      ? _jobs 
      : _filteredJobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getJobs();
      final dynamic rawData = response.data;

      List<dynamic> jobList = [];

      if (rawData is List) {
        jobList = rawData;
      } else if (rawData is Map) {
         // Django REST Framework pagination often uses 'results'
        if (rawData.containsKey('results')) {
          jobList = rawData['results'];
        } else if (rawData.containsKey('data')) {
          jobList = rawData['data'];
        }
      }

      _jobs = jobList
          .map((json) => JobPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load jobs: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('fetchJobs error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createJob(Map<String, dynamic> data, {String? imagePath}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formDataMap = {
        'position': data['position'],
        'no_of_vacancies': data['noOfVacancies'],
        'location': data['location'],
        'salary': data['salary'],
        'working_time': data['workingTime'] ?? 'Full Time',
        'working_days': data['workingDays'] ?? 'Mon-Fri',
        'responsibilities': data['responsibilities'] ?? '',
        'qualifications': data['qualifications'] ?? '',
        'benefits': data['benefits'] ?? '',
        'annual_leave': data['annualLeave'] ?? 0,
        'industry': data['industry'] ?? '',
        'accommodation': data['accommodation'] ?? '',
        'meals': data['meals'] ?? '',
        'category': data['category'] ?? '',
      };

      if (imagePath != null) {
        if (kIsWeb) {
          final XFile file = XFile(imagePath);
          final bytes = await file.readAsBytes();
          formDataMap['image'] = MultipartFile.fromBytes(
            bytes,
            filename: 'job_image.jpg',
          );
        } else {
          formDataMap['image'] = await MultipartFile.fromFile(imagePath);
        }
      }

      final formData = FormData.fromMap(formDataMap);
      await _apiService.createJobPost(formData);
      
      await fetchJobs(); // Refresh the list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create job: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchJobs({String? keyword, String? location}) {
    _searchKeyword = keyword ?? '';
    _searchLocation = location ?? '';

    if (_searchKeyword.isEmpty && _searchLocation.isEmpty) {
      _filteredJobs = [];
      notifyListeners();
      return;
    }

    _filteredJobs = _jobs.where((job) {
      final matchesKeyword = _searchKeyword.isEmpty ||
          job.position.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          job.companyName.toLowerCase().contains(_searchKeyword.toLowerCase());

      final matchesLocation = _searchLocation.isEmpty ||
          job.location.toLowerCase().contains(_searchLocation.toLowerCase());

      return matchesKeyword && matchesLocation;
    }).toList();

    notifyListeners();
  }

  void clearSearch() {
    _searchKeyword = '';
    _searchLocation = '';
    _filteredJobs = [];
    notifyListeners();
  }
}
