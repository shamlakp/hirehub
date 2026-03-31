import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';

class HeroSearchBar extends StatefulWidget {
  const HeroSearchBar({super.key});

  @override
  State<HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends State<HeroSearchBar> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _backgroundImages = [
    'assets/images/slider_1.jpg', // Replace with your first image
    'assets/images/slider_2.jpg', // Replace with your second image
    'assets/images/slider_3.jpg', // Replace with your third image
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startSlideshow();
  }

  void _startSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _backgroundImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _locationController.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _performSearch(BuildContext context) {
    final jobProvider = context.read<JobProvider>();
    jobProvider.searchJobs(
      keyword: _keywordController.text,
      location: _locationController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _keywordController,
          decoration: const InputDecoration(
            hintText: 'Search for jobs...',
            prefixIcon: Icon(Icons.search, color: Color(0xFF673AB7)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
          onSubmitted: (_) => _performSearch(context),
        ),
      ),
    );
  }

}
