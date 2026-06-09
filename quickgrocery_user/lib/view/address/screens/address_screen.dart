import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/view/address/screens/add_address_screen.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/checkout/widgets/address_card.dart';
import 'package:quickgrocery/view/checkout/widgets/checkout_bottom_bar.dart';
import 'package:quickgrocery/view/checkout/widgets/empty_address_widget.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Premium address book — saved addresses with select / edit / swipe-delete.
class AddressScreen extends StatefulWidget {
  static String route = 'address';
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressService>(context, listen: false).getAddress();
    });
  }

  Future<void> _openForm({AddressModel? edit}) async {
    final service = Provider.of<AddressService>(context, listen: false);
    final ok = await Navigator.push<bool>(
      context,
      AppPageRoutes.addAddress(editing: edit),
    );
    if (ok == true) await service.getAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Consumer<AddressService>(
                builder: (context, p, _) {
                  if (p.addresses == null) {
                    return const _LoadingList();
                  }
                  if (p.addresses!.isEmpty) {
                    return EmptyAddressWidget(
                      onAddAddress: _openForm,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColor.primary,
                    onRefresh: () => p.getAddress(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      itemCount: p.addresses!.length + 1,
                      itemBuilder: (context, i) {
                        if (i == p.addresses!.length) {
                          return _AddNewTile(onTap: _openForm);
                        }
                        final a = p.addresses![i];
                        return FadeInUp(
                          duration: Duration(milliseconds: 240 + i * 40),
                          child: SavedAddressCard(
                            address: a,
                            selected: p.selectedIndex == i,
                            onTap: () => p.selectedIndexChange(i),
                            onEdit: () => _openForm(edit: a),
                            onDelete: () => p.removeAddress(a.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<AddressService>(
        builder: (context, p, _) {
          final hasAddr = (p.addresses?.isNotEmpty ?? false);
          return CheckoutBottomBar(
            label: context.l10n.continue_label,
            enabled: hasAddr,
            isLoading: false,
            onPressed: () {
              Navigator.push(context, AppPageRoutes.payment());
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              onBack();
            },
          ),
          Expanded(
            child: Text(
              context.l10n.addresses_title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppSurface.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNewTile extends StatelessWidget {
  const _AddNewTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: DottedDashedContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColor.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.add_address,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DottedDashedContainer extends StatelessWidget {
  const DottedDashedContainer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColor.primary.withValues(alpha: 0.5),
          width: 1.4,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: child,
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      itemCount: 4,
      itemBuilder: (context, i) => Container(
        height: 96,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppSurface.border),
        ),
      ),
    );
  }
}
