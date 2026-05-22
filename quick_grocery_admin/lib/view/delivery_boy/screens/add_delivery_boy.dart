import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';

/// Add delivery boy — scroll handled by [AdminPageSlot] / [AdminPageWrapper].
class AddDeliveryScreen extends StatelessWidget {
  const AddDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building Add Delivery Boy page');
    final provider = context.watch<DeliveryBoyService>();

    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Delivery Boy', style: AppTextStyles.heading),
          const SizedBox(height: 20),
          const DeliveryBoyForm(),
          const SizedBox(height: 20),
          AdminPrimaryButton(
            label: 'Submit',
            isLoading: provider.isLoading,
            onPressed: () => provider.addDeliveryBoy(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Personal + account fields (no nested scroll / flex in unbounded parents).
class DeliveryBoyForm extends StatelessWidget {
  const DeliveryBoyForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryBoyService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        WrapperWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/icons/userplus.svg'),
                  AppSpacing.w10,
                  const Text(
                    'Add new Delivery Boy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,
              _AdminFormRow(
                breakpoint: 720,
                children: [
                  _LabeledField(
                    label: 'First name',
                    child: PrimaryTextField(
                      controller: provider.firstNameController,
                      hintText: 'Ex: Jhone',
                    ),
                  ),
                  _LabeledField(
                    label: 'Last name',
                    child: PrimaryTextField(
                      controller: provider.secondNameController,
                      hintText: 'Ex: K',
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,
              _AdminFormRow(
                breakpoint: 720,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Phone'),
                      AppSpacing.h10,
                      LayoutBuilder(
                        builder: (context, c) {
                          return Row(
                            children: [
                              const Text('+91'),
                              AppSpacing.w10,
                              SizedBox(
                                width: c.maxWidth > 48
                                    ? c.maxWidth - 48
                                    : c.maxWidth,
                                child: PrimaryTextField(
                                  controller: provider.phoneController,
                                  hintText: '9876543210',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  _LabeledField(
                    label: 'Licence number',
                    child: PrimaryTextField(
                      controller: provider.licenceController,
                      hintText: 'Ex: KL XXX0 XX06',
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,
              _AdminFormRow(
                breakpoint: 640,
                children: [
                  _LabeledField(
                    label: 'Address',
                    child: PrimaryTextField(
                      controller: provider.addressController,
                      hintText: 'Ex: second street',
                    ),
                  ),
                  AdminUploadSection(
                    label: 'Profile image (1:1)',
                    buttonLabel: 'Upload image',
                    onTap: provider.pickImage,
                    preview: provider.imageBytes == null
                        ? null
                        : Image.memory(
                            provider.imageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.h20,
        WrapperWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/icons/user.svg'),
                  AppSpacing.w10,
                  const Text('Account information'),
                ],
              ),
              AppSpacing.h20,
              _AdminFormRow(
                breakpoint: 720,
                children: [
                  _LabeledField(
                    label: 'Email',
                    child: PrimaryTextField(
                      controller: provider.emailController,
                      hintText: 'Ex: jhone@gmail.com',
                    ),
                  ),
                  _LabeledField(
                    label: 'Password',
                    child: PrimaryTextField(
                      controller: provider.passwordController,
                      hintText: 'Password',
                    ),
                  ),
                  _LabeledField(
                    label: 'Confirm password',
                    child: PrimaryTextField(
                      controller: provider.confirmController,
                      hintText: 'Confirm password',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        AppSpacing.h10,
        child,
      ],
    );
  }
}

/// Stacks fields on narrow viewports; fixed-width columns on wide (no [Expanded] in scroll).
class _AdminFormRow extends StatelessWidget {
  const _AdminFormRow({
    required this.children,
    this.breakpoint = 720,
  });

  final List<Widget> children;
  final double breakpoint;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                children[i],
              ],
            ],
          );
        }
        final n = children.length;
        final colW = (c.maxWidth - _gap * (n - 1)) / n;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              SizedBox(width: colW, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
