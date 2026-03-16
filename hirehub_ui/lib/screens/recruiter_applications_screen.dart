import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/application_provider.dart';
import '../models/job_application.dart';

class RecruiterApplicationsScreen extends StatefulWidget {
  const RecruiterApplicationsScreen({super.key});

  @override
  State<RecruiterApplicationsScreen> createState() => _RecruiterApplicationsScreenState();
}

class _RecruiterApplicationsScreenState extends State<RecruiterApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ApplicationProvider>().fetchApplications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ApplicationProvider>().fetchApplications(),
          ),
        ],
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.applications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => provider.fetchApplications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.applications.isEmpty) {
            return const Center(child: Text('No applications received yet.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchApplications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.applications.length,
              itemBuilder: (context, index) {
                final application = provider.applications[index];
                return _buildApplicationCard(context, application, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, JobApplication app, ApplicationProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.applicantName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied for: ${app.jobPosition}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(app.status),
              ],
            ),
            const Divider(height: 24),
            if (app.notes.isNotEmpty) ...[
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(app.notes),
              const SizedBox(height: 12),
            ],
            Text(
              'Applied on: ${app.appliedAt.split('T')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (app.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _updateStatus(context, app.id, 'rejected', provider),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateStatus(context, app.id, 'shortlisted', provider),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Shortlist'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'shortlisted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _updateStatus(BuildContext context, int id, String status, ApplicationProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.updateApplicationStatus(id, status);
    
    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text('Application $status successfully')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }
}
