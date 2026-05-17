import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _types = <List<String>>[
    ['license', 'Driving License'],
    ['aadhaar', 'Aadhaar Card'],
    ['pan', 'PAN Card'],
    ['rc', 'Vehicle RC'],
    ['insurance', 'Insurance'],
  ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DriverProfileService>().profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Upload document image URLs (admin will verify). Use a secure image link from your gallery upload.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._types.map((t) {
            final key = t[0];
            final label = t[1];
            final meta = profile?.documents[key];
            final status = meta?.status ?? 'not_uploaded';
            Color statusColor = Colors.orange;
            if (status == 'approved') statusColor = Colors.green;
            if (status == 'rejected') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(label),
                subtitle: Text('Status: $status'),
                trailing: Icon(Icons.circle, size: 12, color: statusColor),
                onTap: () => _showUploadSheet(context, key, label, meta?.url ?? ''),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showUploadSheet(
    BuildContext context,
    String type,
    String label,
    String currentUrl,
  ) {
    final controller = TextEditingController(text: currentUrl);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Document image URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isEmpty) return;
                await context.read<DriverProfileService>().updateDocument(type, url);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document submitted for verification')),
                  );
                }
              },
              child: const Text('Submit for verification'),
            ),
          ],
        ),
      ),
    );
  }
}
