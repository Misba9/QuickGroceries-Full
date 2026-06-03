import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';

/// Edit, stock toggle, and delete actions for a product row.
class ProductListActions extends StatelessWidget {
  const ProductListActions({
    super.key,
    required this.product,
    required this.onEdit,
    this.compact = false,
  });

  final ProductModel product;
  final VoidCallback onEdit;
  final bool compact;

  Future<void> _confirmDelete(BuildContext context, ProductService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final success = await svc.deleteProductPermanently(product);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Product deleted'
              : 'Could not delete product. Try again.',
        ),
      ),
    );
  }

  Future<void> _toggleStock(BuildContext context, ProductService svc) async {
    final wasOutOfStock = product.isOutOfStock;
    final success = wasOutOfStock
        ? await svc.setProductInStock(product)
        : await svc.setProductOutOfStock(product);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (wasOutOfStock
                  ? 'Product marked in stock'
                  : 'Product marked out of stock')
              : 'Update failed. Try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ProductService>();
    final busy = svc.isProductActionBusy(product.id);
    final outOfStock = product.isOutOfStock;

    if (product.isDeleted) {
      return Text(
        'Removed',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      );
    }

    final editBtn = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.primary,
        side: BorderSide(color: AppColor.primary.withValues(alpha: 0.5)),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : null,
      ),
      onPressed: busy ? null : onEdit,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Edit'),
    );

    final stockBtn = outOfStock
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  : null,
            ),
            onPressed: busy ? null : () => _toggleStock(context, svc),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark In Stock'),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade900,
              side: BorderSide(color: Colors.orange.shade400),
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  : null,
            ),
            onPressed: busy ? null : () => _toggleStock(context, svc),
            icon: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange.shade900,
                    ),
                  )
                : const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text('Mark Out of Stock'),
          );

    final deleteBtn = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade300),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : null,
      ),
      onPressed: busy ? null : () => _confirmDelete(context, svc),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          editBtn,
          const SizedBox(height: 8),
          stockBtn,
          const SizedBox(height: 8),
          deleteBtn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        editBtn,
        const SizedBox(height: 8),
        stockBtn,
        const SizedBox(height: 8),
        deleteBtn,
      ],
    );
  }
}
