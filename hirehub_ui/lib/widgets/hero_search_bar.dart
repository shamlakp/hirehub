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

  @override
  void dispose() {
    _keywordController.dispose();
    _locationController.dispose();
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&q=80&w=2074&ixlib=rb-4.0.3'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Find the Best Jobs Worldwide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Trusted recruitment for global careers',
            style: TextStyle(color: Colors.white70, fontSize: 16),
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
                  ),
                  const SizedBox(width: 20),
                  _buildContactItem(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: Colors.greenAccent,
                    onTap: () {
                      if (settings.whatsappLink != null && settings.whatsappLink!.isNotEmpty) {
                        launchUrl(Uri.parse(settings.whatsappLink!), mode: LaunchMode.externalApplication);
                      } else {
                        final whatsappUrl = 'https://wa.me/${settings.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
                        launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
                      }
                    },
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
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
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
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
