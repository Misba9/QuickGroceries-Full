import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Premium selectable address row — used on checkout.
class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.address,
    required this.selected,
    required this.onSelect,
    this.onEdit,
    this.heroTag,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelect();
        },
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColor.primary : AppSurface.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: AppShadow.dim,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeBadge(type: address.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${address.type} · ${address.name}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppSurface.text,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColor.primary,
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${address.address}, ${address.area}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppSurface.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.mobile,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppSurface.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onEdit!();
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppSurface.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final wrapped = heroTag != null
        ? Hero(tag: heroTag!, child: Material(color: Colors.transparent, child: tile))
        : tile;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: wrapped,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  IconData _icon() {
    switch (type.toUpperCase()) {
      case 'OFFICE':
        return Icons.work_outline_rounded;
      case 'OTHER':
        return Icons.place_outlined;
      default:
        return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      alignment: Alignment.center,
      child: Icon(_icon(), color: AppColor.primary, size: 22),
    );
  }
}

/// Saved-address row with swipe-to-delete confirmation — address book screen.
class SavedAddressCard extends StatelessWidget {
  const SavedAddressCard({
    super.key,
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('addr-${address.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                title: Text(
                  context.l10n.delete_address_title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
                content: Text(
                  context.l10n.delete_address_body,
                  style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(context.l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      context.l10n.delete,
                      style: const TextStyle(color: AppSurface.danger),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
        return ok;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppSurface.danger.withValues(alpha: 0.85),
              AppSurface.danger,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              context.l10n.delete,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_sweep_rounded, color: Colors.white),
          ],
        ),
      ),
      child: CheckoutAddressCard(
        address: address,
        selected: selected,
        onSelect: onTap,
        onEdit: onEdit,
      ),
    );
  }
}
