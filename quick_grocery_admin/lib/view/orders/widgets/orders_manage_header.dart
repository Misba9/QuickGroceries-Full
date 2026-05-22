import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';

class OrdersManageHeader extends StatelessWidget {
  const OrdersManageHeader({
    super.key,
    required this.page,
    this.trailing,
  });

  final OrderModulePage page;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(page.title, style: AppTextStyles.heading),
            if (page.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(page.subtitle!, style: AppTextStyles.dashboardSubtitle),
            ],
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
