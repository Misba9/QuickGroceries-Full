import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text('notification_center'.tr())),
        body: const Center(child: Text('Sign in to see notifications')),
      );
    }

    final col = FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('notification_inbox')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(
        title: Text('notification_center'.tr()),
        actions: [
          TextButton(
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final snap = await col.get();
              for (final d in snap.docs) {
                batch.update(d.reference, {'read': true});
              }
              await batch.commit();
            },
            child: Text('mark_all_read'.tr()),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('something_went_wrong'.tr()));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet. Offers and orders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();
              final title = (m['title'] ?? '').toString();
              final body = (m['body'] ?? '').toString();
              final read = m['read'] == true;
              return Material(
                color: read
                    ? Colors.white
                    : AppColor.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(
                    title.isEmpty ? 'Quick Grocery' : title,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(body),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await d.reference.update({'read': true});
                    final redirect = (m['redirectType'] ?? '').toString();
                    final deepLink = (m['deepLink'] ?? '').toString();
                    final logId = (m['logId'] ?? '').toString();
                    await handlePushNavigation({
                      'redirectType': redirect,
                      'deepLink': deepLink,
                      'logId': logId,
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
