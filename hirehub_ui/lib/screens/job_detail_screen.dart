
import 'package:flutter/material.dart';
import 'package:hirehub_ui/models/job_post.dart';
import 'package:hirehub_ui/utils/url_helper.dart';
import 'apply_job_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final JobPost job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          job.companyName,
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              color: Colors.grey[50],
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: (job.image != null && job.image!.isNotEmpty)
                          ? Image.network(
                              _getImageUrl(job.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.business, size: 40, color: Colors.grey),
                            )
                          : const Icon(Icons.business, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.position,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${job.location} • ${job.workingTime}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Job Description'),
                  _buildSectionContent(job.responsibilities.isNotEmpty 
                      ? job.responsibilities 
                      : 'No detailed description provided.'),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Requirements'),
                  _buildSectionContent(job.qualifications.isNotEmpty 
                      ? job.qualifications 
                      : 'No specific requirements listed.'),

                  const SizedBox(height: 24),
                  
                  if (job.benefits.isNotEmpty) ...[
                    _buildSectionTitle('Benefits'),
                    _buildSectionContent(job.benefits),
                    const SizedBox(height: 24),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  // Key Details Grid
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildDetailItem(Icons.attach_money, 'Salary', '\$${job.salary}'),
                      _buildDetailItem(Icons.schedule, 'Work Schedule', job.workingDays),
                      _buildDetailItem(Icons.people, 'Vacancies', '${job.noOfVacancies} Openings'),
                      if (job.annualLeave > 0)
                        _buildDetailItem(Icons.flight_takeoff, 'Annual Leave', '${job.annualLeave} Days'),
                      if (job.category.isNotEmpty) 
                        _buildDetailItem(Icons.category, 'Category', job.category),
                      if (job.industry.isNotEmpty) 
                        _buildDetailItem(Icons.business, 'Industry', job.industry),
                      if (job.accommodation.isNotEmpty) 
                        _buildDetailItem(Icons.home_work, 'Accommodation', job.accommodation),
                      if (job.meals.isNotEmpty) 
                        _buildDetailItem(Icons.restaurant, 'Meals', job.meals),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ApplyJobScreen(job: job)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('Apply Now'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return SizedBox(
      width: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '${UrlHelper.getBaseUrl()}$path';
  }
}
