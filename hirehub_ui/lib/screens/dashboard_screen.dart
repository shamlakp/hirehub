import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/platform_provider.dart';
import '../widgets/job_grid_card.dart';
import '../widgets/filter_sidebar.dart';
import '../widgets/hero_search_bar.dart';
import '../widgets/hirehub_logo.dart';
import '../utils/url_helper.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'applicant_profile_screen.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';
import 'recruiter_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<JobProvider>().fetchJobs();
        context.read<PlatformProvider>().fetchSettings();
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
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
      if (mounted) {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.userData?['username'] ?? 'User';
    final userType = auth.userData?['user_type'] ?? 'applicant';
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const HireHubLogo(fontSize: 20),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!auth.isAuthenticated) ...[
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Sign Up', style: TextStyle(color: Colors.black87)),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: const Text('Sign In'),
              ),
            ),
          ] else ...[
            if (userType == 'admin')
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await UrlHelper.launchBackendUrl('/adminpanel/dashboard/');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('Admin Panel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF673AB7),
                    side: const BorderSide(color: Color(0xFF673AB7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            if (userType == 'applicant')
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.black87),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApplicantProfileScreen()),
                ),
              ),
            if (userType == 'recruiter')
              IconButton(
                icon: const Icon(Icons.business_center_outlined, color: Colors.black87), // Distinguish icon
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecruiterProfileScreen()),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: () => _logout(context),
                child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: isDesktop ? null : _buildDrawer(context, username, userType),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HeroSearchBar(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDesktop) const FilterSidebar(),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSortAndFoundRow(),
                          const SizedBox(height: 24),
                          _buildJobGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: userType == 'recruiter'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateJobScreen())),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
            )
          : null,
    );
  }

  Widget _buildSortAndFoundRow() {
    return Consumer<JobProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Text(
              '${provider.jobs.length} Jobs found',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => provider.clearSearch(),
              child: const Text('Clear All'),
            ),
            const Spacer(),
            const Text('Sort by '),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'Relevance',
                  isDense: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  items: ['Relevance', 'Newest First', 'Salary: High to Low']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {},
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
            childAspectRatio: size.width > 900 ? 2.0 : 1.3,
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
                _logout(context);
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
}
