import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/checkout/widgets/delivery_slot_chip.dart';

class DeliverySlotSelector extends StatelessWidget {
  const DeliverySlotSelector({
    super.key,
    required this.slots,
    required this.selected,
    required this.onChanged,
  });

  final List<DeliverySlot> slots;
  final DeliverySlot? selected;
  final ValueChanged<DeliverySlot> onChanged;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: AppSurface.of(context).text),
            SizedBox(width: 8),
            Text(
              'Delivery slot',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppSurface.of(context).text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: slots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final slot = slots[i];
              final isSel = selected?.id == slot.id;
              return DeliverySlotChip(
                label: slot.label,
                selected: isSel,
                isExpress: slot.isExpress,
                onTap: () => onChanged(slot),
              );
            },
          ),
        ),
      ],
    );
  }
}
