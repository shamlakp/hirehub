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
  List<String> _searchCategories = [];
  List<String> _searchJobTypes = [];
  double _minSalary = 0;
  double _maxSalary = 100000000; // Reduced to 100M after data cleanup
  String _currentSort = 'Relevance';

  String get currentSort => _currentSort;

  List<JobPost> get jobs {
    // Robust null-safety for web hot reload
    final hasNoKeyword = _searchKeyword == null || _searchKeyword.isEmpty;
    final hasNoLocation = _searchLocation == null || _searchLocation.isEmpty;
    final hasNoCategories = _searchCategories == null || _searchCategories.isEmpty;
    final hasNoJobTypes = _searchJobTypes == null || _searchJobTypes.isEmpty;
    final hasDefaultSalary = _minSalary == 0 && _maxSalary == 100000000;

    return (_filteredJobs == null || _filteredJobs.isEmpty) && 
           hasNoKeyword && 
           hasNoLocation && 
           hasNoCategories && 
           hasNoJobTypes &&
           hasDefaultSalary
        ? _jobs 
        : _filteredJobs;
  }
  
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
        'company': data['company'], // Include company ID for multi-company support
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

  void searchJobs({
    String? keyword,
    String? location,
    List<String>? categories,
    List<String>? jobTypes,
    double? minSalary,
    double? maxSalary,
  }) {
    _searchKeyword = keyword ?? _searchKeyword;
    _searchLocation = location ?? _searchLocation;
    _searchCategories = categories ?? _searchCategories;
    _searchJobTypes = jobTypes ?? _searchJobTypes;
    _minSalary = minSalary ?? _minSalary;
    _maxSalary = maxSalary ?? _maxSalary;

    final hasNoKeyword = _searchKeyword == null || _searchKeyword.isEmpty;
    final hasNoLocation = _searchLocation == null || _searchLocation.isEmpty;
    final hasNoCategories = _searchCategories == null || _searchCategories.isEmpty;
    final hasNoJobTypes = _searchJobTypes == null || _searchJobTypes.isEmpty;

    if (hasNoKeyword && 
        hasNoLocation && 
        hasNoCategories && 
        hasNoJobTypes &&
        _minSalary == 0 && 
        _maxSalary == 100000000) {
      _filteredJobs = [];
      notifyListeners();
      return;
    }

    _filteredJobs = _jobs.where((job) {
      final matchesKeyword = (_searchKeyword == null || _searchKeyword.isEmpty) ||
          job.position.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          job.companyName.toLowerCase().contains(_searchKeyword.toLowerCase());

      final matchesLocation = (_searchLocation == null || _searchLocation.isEmpty) ||
          job.location.toLowerCase().contains(_searchLocation.toLowerCase());

      // Helper to normalize strings for comparison (remove spaces/hyphens and lowercase)
      String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');

      final matchesCategory = (_searchCategories == null || _searchCategories.isEmpty) || 
          _searchCategories.any((cat) => 
            normalize(job.category).contains(normalize(cat)) || 
            normalize(cat).contains(normalize(job.category))
          );

      final matchesJobType = (_searchJobTypes == null || _searchJobTypes.isEmpty) ||
          _searchJobTypes.any((type) => 
            normalize(job.workingTime).contains(normalize(type)) ||
            normalize(type).contains(normalize(job.workingTime))
          );

      // Parse salary safely
      double salaryValue = 0;
      try {
        salaryValue = double.parse(job.salary.replaceAll(RegExp(r'[^0-9.]'), ''));
      } catch (_) {}

      final matchesSalary = salaryValue >= _minSalary && salaryValue <= _maxSalary;

      return matchesKeyword && matchesLocation && matchesCategory && matchesJobType && matchesSalary;
    }).toList();

    _applySort();
    notifyListeners();
  }

  void setSort(String criteria) {
    _currentSort = criteria;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    if (_currentSort == 'Newest First') {
      _jobs.sort((a, b) => b.id.compareTo(a.id));
      if (_filteredJobs.isNotEmpty) {
        _filteredJobs.sort((a, b) => b.id.compareTo(a.id));
      }
    } else if (_currentSort == 'Salary: High to Low') {
      double getSalary(JobPost j) {
        try {
          return double.parse(j.salary.replaceAll(RegExp(r'[^0-9.]'), ''));
        } catch (_) {
          return 0;
        }
      }
      _jobs.sort((a, b) => getSalary(b).compareTo(getSalary(a)));
      if (_filteredJobs.isNotEmpty) {
        _filteredJobs.sort((a, b) => getSalary(b).compareTo(getSalary(a)));
      }
    } else {
      // Relevance/Default - usually by ID or original order
      _jobs.sort((a, b) => b.id.compareTo(a.id));
      if (_filteredJobs.isNotEmpty) {
        _filteredJobs.sort((a, b) => b.id.compareTo(a.id));
      }
    }
  }

  void clearSearch() {
    _searchKeyword = '';
    _searchLocation = '';
    _searchCategories = [];
    _searchJobTypes = [];
    _minSalary = 0;
    _maxSalary = 100000000;
    _filteredJobs = [];
    notifyListeners();
  }
}
