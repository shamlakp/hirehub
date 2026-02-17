import 'package:flutter/material.dart';
import '../models/job_post.dart';
import '../utils/url_helper.dart';

class JobGridCard extends StatelessWidget {
  final JobPost job;
  final VoidCallback? onTap;

  const JobGridCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small Image/Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (job.image != null && job.image!.isNotEmpty)
                            ? Image.network(
                                _getImageUrl(job.image!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(Icons.business, size: 40, color: Colors.grey[400]),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.business,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.position,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Salary
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      '\$${job.salary}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D47A1),
                      side: const BorderSide(color: Color(0xFF0D47A1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    // Ensure the path starts with /
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    final url = '${UrlHelper.getBaseUrl()}$path';
    debugPrint('Constructed image URL: $url');
    return url;
  }
}
