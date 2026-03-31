
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'applicant_profile_screen.dart';
import 'applicant_applications_screen.dart';
import 'dashboard_screen.dart';

class ApplicantDashboardScreen extends StatefulWidget {
  const ApplicantDashboardScreen({super.key});

  @override
  State<ApplicantDashboardScreen> createState() => _ApplicantDashboardScreenState();
}

class _ApplicantDashboardScreenState extends State<ApplicantDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _applications = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'pending': 0,
    'shortlisted': 0,
    'rejected': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiService();
      final response = await api.getApplications();
      if (response.statusCode == 200) {
        final List<dynamic> apps = response.data;
        int pending = 0;
        int shortlisted = 0;
        int rejected = 0;

        for (var app in apps) {
          final status = (app['status'] ?? '').toString().toLowerCase();
          if (status == 'pending') {
            pending++;
          } else if (status == 'shortlisted' || status == 'accepted') {
            shortlisted++;
          } else if (status == 'rejected') {
            rejected++;
          }
        }

        if (mounted) {
          setState(() {
            _applications = apps;
            _stats = {
              'total': apps.length,
              'pending': pending,
              'shortlisted': shortlisted,
              'rejected': rejected,
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userData;
    final fullName = user?['full_name'] ?? user?['username'] ?? 'Applicant';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $fullName!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your applications and find your next opportunity.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Applications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ApplicantApplicationsScreen()),
                          ),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_applications.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _applications.length > 5 ? 5 : _applications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          return _buildApplicationCard(app);
                        },
                      ),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 1.5 : 0.85,
        children: [
          _buildStatCard('Total Applied', _stats['total'].toString(), Icons.assignment_outlined, Colors.blue),
          _buildStatCard('Pending', _stats['pending'].toString(), Icons.hourglass_empty, Colors.orange),
          _buildStatCard('Shortlisted', _stats['shortlisted'].toString(), Icons.check_circle_outline, Colors.green),
          _buildStatCard('Rejected', _stats['rejected'].toString(), Icons.cancel_outlined, Colors.red),
        ],
      );
    });
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final job = app['job_details'] ?? {};
    final company = job['company_name'] ?? 'Company';
    final title = job['title'] ?? 'Job Title';
    final status = app['status'] ?? 'Pending';
    final appliedAt = app['created_at'] != null 
        ? app['created_at'].toString().split('T')[0] 
        : 'Recently';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  company,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(status),
              const SizedBox(height: 4),
              Text(
                appliedAt,
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'shortlisted' || status.toLowerCase() == 'accepted') color = Colors.green;
    if (status.toLowerCase() == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No applications yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const DashboardScreen())
              ),
              child: const Text('Find your first job'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Browse Jobs', 
                Icons.search, 
                Colors.indigo,
                () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Edit Profile', 
                Icons.person_outline, 
                Colors.deepPurple,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplicantProfileScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
