import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_global_top_bar.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_top_bar_actions.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/partner_security/partner_security_sheet.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_details.dart';
import 'package:quick_grocery_admin/view/vendor/widgets/vendor_auth_recovery_sheet.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/widgets/admin_text_selection.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<VendorService>(context, listen: false).gettVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/userplus.svg'),
                      AppSpacing.w10,
                      Expanded(
                        child: Text(
                          'Vendor List',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h20,
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vendors…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) => context
                        .read<VendorService>()
                        .setVendorSearch(v),
                  ),
                  AppSpacing.h10,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in [
                          'all',
                          'approved',
                          'inactive',
                          'suspended',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f[0].toUpperCase() + f.substring(1)),
                              selected:
                                  context.watch<VendorService>().vendorStatusFilter ==
                                      f,
                              onSelected: (_) => context
                                  .read<VendorService>()
                                  .setVendorStatusFilter(f),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.h15,
                  Consumer<VendorService>(
                    builder: (context, svc, _) {
                      final honey = svc.findVendorByShopName('Honey Traders');
                      if (honey == null || !honey.needsFirebaseAuthSync) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            leading: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade800,
                            ),
                            title: const Text(
                              'Honey Traders needs Firebase Auth sync',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${honey.email} · Tap to restore login',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: FilledButton(
                              onPressed: () => VendorAuthRecoverySheet.show(
                                context,
                                honey,
                              ),
                              child: const Text('Restore'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  WrapperWidget(
                    child: Column(
                      children: [
                        Consumer<VendorService>(
                          builder: (context, p, _) {
                            if (p.vendorsLoading && p.vendors == null) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (p.loadError != null) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  p.loadError!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              );
                            }
                            final list = p.filteredVendors;
                            if (list.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No vendors found.'),
                              );
                            }
                            return LayoutBuilder(
                              builder: (context, c) {
                                final colSpace =
                                    (c.maxWidth * 0.03).clamp(8.0, 24.0);
                                final dataTable = DataTable(
                                  columnSpacing: colSpace,
                                  dataRowMinHeight: 70,
                                  dataRowMaxHeight: 80,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'SL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Shop Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Owner',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Contact Info',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total Products',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total Orders',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Firebase Auth',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Action',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: List.generate(list.length, (index) {
                              final v = list[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 260,
                                      ),
                                      child: Row(
                                        children: [
                                          _vendorThumb(v.shopImage),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: AdminSelectableText(
                                              v.shopName,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    AdminSelectableText(
                                      v.ownerName,
                                      maxLines: 2,
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AdminSelectableText(
                                            v.phone,
                                            maxLines: 1,
                                          ),
                                          AdminSelectableText(
                                            v.email,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(_statusBadge(v)),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.deepOrange.shade100,
                                      ),
                                      child: Text('${p.productCountFor(v.id)}'),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.deepOrange.shade100,
                                      ),
                                      child: Text('${p.orderCountFor(v.id)}'),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: v.needsFirebaseAuthSync
                                            ? Colors.orange.shade100
                                            : Colors.green.shade100,
                                      ),
                                      child: Text(
                                        v.needsFirebaseAuthSync
                                            ? 'Not synced'
                                            : 'Synced',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: v.needsFirebaseAuthSync
                                              ? Colors.orange.shade900
                                              : Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.build_circle_outlined,
                                            color: Colors.deepPurple,
                                          ),
                                          tooltip: 'Auth recovery tools',
                                          onPressed: () =>
                                              VendorAuthRecoverySheet.show(
                                            context,
                                            v,
                                          ),
                                        ),
                                        if (v.needsFirebaseAuthSync)
                                          IconButton(
                                            icon: Icon(
                                              Icons.sync,
                                              color: Colors.orange.shade800,
                                            ),
                                            tooltip: 'Sync Firebase Auth',
                                            onPressed: () async {
                                              final passwordController =
                                                  TextEditingController();
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Sync Firebase Auth',
                                                  ),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.stretch,
                                                    children: [
                                                      Text(
                                                        'Create Firebase login for ${v.email}. '
                                                        'Vendor will use this password in the vendor app.',
                                                      ),
                                                      const SizedBox(height: 12),
                                                      TextField(
                                                        controller: passwordController,
                                                        obscureText: true,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Password (min 8 chars)',
                                                          border: OutlineInputBorder(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx, true),
                                                      child: const Text('Sync'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok != true ||
                                                  passwordController.text.length < 8) {
                                                passwordController.dispose();
                                                return;
                                              }
                                              if (!context.mounted) {
                                                passwordController.dispose();
                                                return;
                                              }
                                              await Provider.of<VendorService>(
                                                context,
                                                listen: false,
                                              ).migrateVendorAuth(
                                                context,
                                                vendorDocId: v.id,
                                                password: passwordController.text,
                                              );
                                              passwordController.dispose();
                                            },
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.security,
                                            color: Colors.blueGrey,
                                          ),
                                          tooltip: 'Account security',
                                          onPressed: () {
                                            PartnerSecuritySheet.show(
                                              context,
                                              role: 'vendor',
                                              partnerId: v.id,
                                              email: v.email,
                                              isActive: v.isActive,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            color: AppColor.primary,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VendorDetailsScreen(
                                                      vendorId:
                                                          v.id,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                                );
                                return adminScrollableDataTable(
                                  viewportWidth: c.maxWidth,
                                  dataTable: dataTable,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendorThumb(String url) {
    if (url.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey.shade200,
        child: const Icon(Icons.store, size: 22),
      );
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      ),
    );
  }

  Widget _statusBadge(VendorModel v) {
    Color bg;
    Color fg;
    switch (v.displayStatus) {
      case 'approved':
      case 'active':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case 'suspended':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case 'inactive':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        v.displayStatus,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class PrimaryAppBar extends StatelessWidget {
  const PrimaryAppBar({super.key, this.isBackButton = false, this.title});
  final bool isBackButton;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: AdminGlobalTopBar.barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (isBackButton)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title ?? (isBackButton ? 'Details' : 'Quick Grocery Admin'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  const AdminTopBarActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
