import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blocks driver app when maintenance affects delivery partners.
class DriverMaintenanceGate extends StatelessWidget {
  const DriverMaintenanceGate({super.key, required this.child});

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
        final affectsDriver = affected['driver'] as bool? ?? false;

        if (!enabled || !affectsDriver) return child;

        final title = _localized(data['title'], 'en');
        final message = _localized(data['message'], 'en');

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF81C784)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delivery_dining_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
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
