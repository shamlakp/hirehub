import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/platform_provider.dart';
import '../widgets/job_grid_card.dart';
import '../widgets/filter_sidebar.dart';
import '../widgets/hero_search_bar.dart';
import '../utils/url_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'applicant_profile_screen.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';
import 'recruiter_profile_screen.dart';
import 'recruiter_applications_screen.dart';
import 'applicant_applications_screen.dart';
import 'admin_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final jobProvider = context.read<JobProvider>();
    final platformProvider = context.read<PlatformProvider>();
    Future.microtask(() {
      jobProvider.fetchJobs();
      platformProvider.fetchSettings();
    });
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await authProvider.logout();
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.userData?['username'] ?? 'User';
    final userType = auth.userData?['user_type'] ?? 'applicant';
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 160,
        leading: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.location_on_outlined, color: Color(0xFF673AB7), size: 20),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You are in', style: TextStyle(color: Colors.grey, fontSize: 10)),
                Text(
                  'Kannur',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        title: null,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isDesktop && userType == 'admin') ...[
            TextButton.icon(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20, color: Color(0xFF673AB7)),
              label: const Text('Admin Dashboard', style: TextStyle(color: Color(0xFF673AB7))),
              onPressed: () => UrlHelper.launchBackendUrl('/adminpanel/dashboard/'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.settings_suggest_outlined, size: 20, color: Colors.orangeAccent),
              label: const Text('Django Admin', style: TextStyle(color: Colors.orangeAccent)),
              onPressed: () => UrlHelper.launchBackendUrl('/admin/'),
            ),
            const VerticalDivider(width: 32, indent: 12, endIndent: 12),
          ],
          if (isDesktop) ...[
            if (auth.isAuthenticated)
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                label: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            const SizedBox(width: 16),
          ],
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF673AB7)),
            onPressed: () {
              // Notifications placeholder
            },
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: isDesktop ? null : _buildDrawer(context, username, userType),
      endDrawer: isDesktop ? null : const Drawer(
        child: SafeArea(child: FilterSidebar()),
      ),
      body: _currentIndex == 0 
          ? _buildHomeBody(context, isDesktop, userType)
          : _buildOtherScreen(_currentIndex, userType),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF673AB7),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: userType == 'recruiter' && _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateJobScreen())),
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHomeBody(BuildContext context, bool isDesktop, String userType) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Search Bar
          const HeroSearchBar(),
          
          const SizedBox(height: 16),
          
          // 2. Categories Section (Round symbols)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 6,
              itemBuilder: (context, index) {
                final categories = ['IT', 'Design', 'Sales', 'Finance', 'HR', 'Support'];
                final icons = [Icons.laptop, Icons.brush, Icons.trending_up, Icons.account_balance, Icons.people, Icons.headset_mic];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icons[index % icons.length], color: const Color(0xFF673AB7)),
                      ),
                      const SizedBox(height: 8),
                      Text(categories[index % categories.length], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 16),
          
          const SizedBox(height: 16),
          
          // 3. Compact Hero Section with Contact Buttons
          _buildCompactHero(context),

          const SizedBox(height: 24),

          // 4. Jobs Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSortAndFoundRow(),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) const FilterSidebar(),
                  if (isDesktop) const SizedBox(width: 32),
                  Expanded(
                    child: _buildJobGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherScreen(int index, String userType) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Please sign in to view this page'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    if (index == 1) {
      // For now, these still return Scaffolds which might cause double AppBars.
      // In a real app we'd refactor them to be just the body.
      return userType == 'applicant' ? const ApplicantApplicationsScreen() : const RecruiterApplicationsScreen();
    } else {
      if (userType == 'admin') return const AdminProfileScreen();
      return userType == 'applicant' ? const ApplicantProfileScreen() : const RecruiterProfileScreen();
    }
  }

  Widget _buildSortAndFoundRow() {
    return Consumer<JobProvider>(
      builder: (context, provider, child) {
        final isMobile = MediaQuery.of(context).size.width <= 900;
        return Row(
          children: [
            if (isMobile)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF673AB7)),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  tooltip: 'Filter Jobs',
                ),
              ),
            Expanded(
              child: Text(
                '${provider.jobs.length} Jobs found',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            if (!isMobile)
              TextButton(
                onPressed: () => provider.clearSearch(),
                child: const Text('Clear All'),
              ),
            if (!isMobile) const Spacer(),
            const Text('Sort by '),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.currentSort,
                  isDense: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  items: ['Relevance', 'Newest First', 'Salary: High to Low']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      provider.setSort(val);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJobGrid() {
    return Consumer<JobProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                Text(provider.errorMessage!),
                ElevatedButton(
                  onPressed: () => provider.fetchJobs(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (provider.jobs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No jobs found'),
            ),
          );
        }

        final size = MediaQuery.of(context).size;
        int crossAxisCount = 1;
        if (size.width > 1100) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: size.width > 900 ? 2.0 : 1.0,
          ),
          itemCount: provider.jobs.length,
          itemBuilder: (context, index) {
          return JobGridCard(
              job: provider.jobs[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailScreen(job: provider.jobs[index]), // Fix: Pass job object
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, String username, String userType) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: Text(userType.toUpperCase()),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF673AB7)),
            ),
            decoration: const BoxDecoration(color: Color(0xFF673AB7)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          if (userType == 'applicant')
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('My Applications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApplicantApplicationsScreen()),
                );
              },
            ),
          if (userType == 'recruiter')
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Manage Applications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecruiterApplicationsScreen()),
                );
              },
            ),
          if (userType == 'admin') ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'ADMIN PANEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blueAccent),
              title: const Text('Admin Dashboard'),
              subtitle: const Text('Manage jobs & recruiters'),
              onTap: () {
                Navigator.pop(context);
                UrlHelper.launchBackendUrl('/adminpanel/dashboard/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest_outlined, color: Colors.orangeAccent),
              title: const Text('Django Admin'),
              subtitle: const Text('Core database management'),
              onTap: () {
                Navigator.pop(context);
                UrlHelper.launchBackendUrl('/admin/');
              },
            ),
          ],
          const Divider(),
          if (context.watch<AuthProvider>().isAuthenticated)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFF673AB7)),
              title: const Text('Sign In'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompactHero(BuildContext context) {
    return Consumer<PlatformProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        if (settings == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 140, // Compact height
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/images/slider_1.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Looking for a job?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Contact us for immediate help',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildCircleIcon(
                            icon: Icons.phone,
                            color: Colors.white,
                            bgColor: const Color(0xFF673AB7),
                            onTap: () => launchUrl(Uri.parse('tel:${settings.phoneNumber}')),
                          ),
                          const SizedBox(width: 12),
                          _buildCircleIcon(
                            icon: Icons.chat,
                            color: Colors.white,
                            bgColor: const Color(0xFF25D366),
                            onTap: () {
                              final whatsappUrl = 'https://wa.me/${settings.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
                              launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
