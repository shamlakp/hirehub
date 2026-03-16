import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/platform_provider.dart';
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
    'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&q=80&w=2074',
    'assets/images/mezban_logo.jpeg',
    'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&q=80&w=2074',
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
    final bool isWhiteBackground = _currentPage == 1;
    final Color contentColor = isWhiteBackground ? Colors.black87 : Colors.white;
    final Color subContentColor = isWhiteBackground ? Colors.black54 : Colors.white70;

    return Container(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Slideshow
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _backgroundImages.length,
            itemBuilder: (context, index) {
              if (index == 1) {
                // Special White Slide with Side Logo
                return Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -20,
                        bottom: -20,
                        child: Opacity(
                          opacity: 0.15,
                          child: Image.asset(
                            'assets/images/mezban_logo.jpeg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40.0),
                          child: SizedOverflowBox(
                            size: const Size(200, 200),
                            child: Image.asset(
                              'assets/images/mezban_logo.jpeg',
                              width: 300,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final isAsset = _backgroundImages[index].startsWith('assets/');
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: isAsset
                        ? AssetImage(_backgroundImages[index]) as ImageProvider
                        : NetworkImage(_backgroundImages[index]),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
              );
            },
          ),
          // Content on top
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Find the Best Jobs Worldwide',
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trusted recruitment for global careers',
                    style: TextStyle(color: subContentColor, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Admin Contact Details
                  Consumer<PlatformProvider>(
                    builder: (context, provider, child) {
                      final settings = provider.settings;
                      if (settings == null) return const SizedBox.shrink();
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildContactItem(
                            icon: Icons.phone,
                            label: settings.phoneNumber,
                            onTap: () => launchUrl(Uri.parse('tel:${settings.phoneNumber}')),
                            color: contentColor,
                          ),
                          const SizedBox(width: 20),
                          _buildContactItem(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            color: isWhiteBackground ? const Color(0xFF25D366) : Colors.greenAccent,
                            onTap: () {
                              if (settings.whatsappLink != null && settings.whatsappLink!.isNotEmpty) {
                                launchUrl(Uri.parse(settings.whatsappLink!), mode: LaunchMode.externalApplication);
                              } else {
                                final whatsappUrl = 'https://wa.me/${settings.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
                                launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
                              }
                            },
                            textColor: contentColor,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isWhiteBackground ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ] : null,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _keywordController,
                            decoration: const InputDecoration(
                              hintText: 'Job title or keyword',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            onSubmitted: (_) => _performSearch(context),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'Location',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            onSubmitted: (_) => _performSearch(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _performSearch(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            elevation: 0,
                          ),
                          child: const Text('Search Jobs'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Page Indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _backgroundImages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
