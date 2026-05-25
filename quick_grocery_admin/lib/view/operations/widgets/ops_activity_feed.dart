import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';

class OpsActivityFeed extends StatelessWidget {
  const OpsActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = context.select<OpsDashboardService, List<OpsActivityEntry>>(
      (s) => s.recentActivities,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time platform events',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No activity yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 12 ? 12 : activities.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) {
                final a = activities[i];
                final time = a.createdAt != null
                    ? DateFormat('HH:mm').format(a.createdAt!)
                    : '';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: a.color.withValues(alpha: 0.12),
                    child: Icon(a.icon, size: 18, color: a.color),
                  ),
                  title: Text(
                    a.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  trailing: time.isEmpty
                      ? null
                      : Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
