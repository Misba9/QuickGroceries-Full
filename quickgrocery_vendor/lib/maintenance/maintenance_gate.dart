import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blocks vendor app when `app_config/maintenance` affects vendor.
class VendorMaintenanceGate extends StatelessWidget {
  const VendorMaintenanceGate({super.key, required this.child});

  final Widget child;

  static const _docPath = 'app_config/maintenance';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.doc(_docPath).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data!.data() ?? {};
        final enabled =
            data['enabled'] as bool? ?? data['maintenance'] as bool? ?? false;
        final affected = data['affectedApps'] as Map<String, dynamic>? ?? {};
        final affectsVendor = affected['vendor'] as bool? ?? false;

        if (!enabled || !affectsVendor) return child;

        final mode = data['mode']?.toString() ?? 'hard';
        if (mode != 'hard' && mode != 'soft' && mode != 'read_only') {
          return child;
        }

        final title = _localized(data['title'], 'en');
        final message = _localized(data['message'], 'en');
        final phone = data['supportPhone']?.toString() ?? '';

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFF8E1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 72),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Support: $phone', style: GoogleFonts.poppins()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _localized(dynamic raw, String lang) {
    if (raw is String) return raw;
    if (raw is Map) return raw[lang]?.toString() ?? raw['en']?.toString() ?? '';
    return 'Maintenance';
  }
}
