import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_validations.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/checkout/widgets/checkout_bottom_bar.dart';
import 'package:quickgrocery/view/checkout/widgets/premium_text_field.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';

/// Premium "Save address" form — keyboard-safe, modern inputs, address-type
/// pill selector, sticky save CTA, optional map / current-location helpers.
class AddAdressScreen extends StatefulWidget {
  static String route = 'add_address';
  const AddAdressScreen({super.key, this.editing});

  /// When non-null the form is in *edit* mode and updates this document.
  final AddressModel? editing;

  @override
  State<AddAdressScreen> createState() => _AddAdressScreenState();
}

class _AddAdressScreenState extends State<AddAdressScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<AddressService>(context, listen: false);
      if (widget.editing != null) {
        p.loadAddressForEdit(widget.editing!);
      } else {
        p.prepareNewAddress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddressService>(context);
    final isEdit = widget.editing != null;

    return Scaffold(
      backgroundColor: AppSurface.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: isEdit ? 'Edit address' : 'save_address'.tr(),
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeInUp(
                        duration: const Duration(milliseconds: 260),
                        child: _LocationHelpers(),
                      ),
                      const SizedBox(height: 18),
                      PremiumTextField(
                        label: 'full_name'.tr(),
                        controller: provider.nameController,
                        validator: AppValidations.validateName,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppSurface.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PremiumTextField(
                        label: 'mobile_number'.tr(),
                        controller: provider.mobileController,
                        validator: AppValidations.validateMobile,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        prefixIcon: Icon(
                          Icons.call_outlined,
                          color: AppSurface.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PremiumTextField(
                        label: 'house_no_building'.tr(),
                        controller: provider.addressController,
                        validator: AppValidations.validateHouse,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(
                          Icons.home_outlined,
                          color: AppSurface.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PremiumTextField(
                        label: 'road_name_area'.tr(),
                        controller: provider.areaController,
                        validator: AppValidations.validateArea,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icon(
                          Icons.add_road_outlined,
                          color: AppSurface.textMuted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Save as',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppSurface.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TypeSelector(
                        selected: provider.addressType,
                        onChanged: provider.addressTypeChange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CheckoutBottomBar(
              label: 'save_address_button'.tr(),
              enabled: !provider.isLoading,
              isLoading: provider.isLoading,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  provider.addAddress(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
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
              title,
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

class _LocationHelpers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              icon: Icons.my_location_rounded,
              label: 'use_current_location'.tr(),
              onTap: () async {
                final p = Provider.of<AddressService>(context, listen: false);
                await p.getCurrentLocation(context, force: true);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PillButton(
              icon: Icons.map_outlined,
              label: 'pick_on_map'.tr(),
              onTap: () {
                Navigator.push(context, AppPageRoutes.location());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColor.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = [
    _Option('HOME', Icons.home_rounded),
    _Option('OFFICE', Icons.work_outline_rounded),
    _Option('OTHER', Icons.place_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final isSel = opt.value == selected.toUpperCase();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.emphasized,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(opt.value);
                  },
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColor.primary.withValues(alpha: 0.14)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isSel ? AppColor.primary : AppSurface.border,
                        width: isSel ? 1.5 : 1,
                      ),
                      boxShadow: isSel ? AppShadow.dim : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 20,
                          color: isSel ? AppColor.primary : AppSurface.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _labelFor(opt.value),
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isSel ? AppSurface.text : AppSurface.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case 'HOME':
        return 'home'.tr();
      case 'OFFICE':
        return 'office'.tr();
      default:
        return 'other_label'.tr();
    }
  }
}

class _Option {
  const _Option(this.value, this.icon);
  final String value;
  final IconData icon;
}

/// Backwards-compatible `PrimaryTextField` used by older auth/profile screens.
/// New code should use [PremiumTextField] directly.
// ignore: must_be_immutable
class PrimaryTextField extends StatelessWidget {
  PrimaryTextField({
    super.key,
    required this.title,
    required this.controller,
    this.validator,
  });

  final String title;
  final TextEditingController controller;
  FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppSurface.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        PremiumTextField(
          label: title,
          controller: controller,
          validator: validator,
        ),
      ],
    );
  }
}
