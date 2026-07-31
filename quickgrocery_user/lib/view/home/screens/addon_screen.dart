import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

class AddonSelector extends StatefulWidget {
  final List<ProductModel> addons;
  final ProductModel product;

  const AddonSelector({super.key, required this.addons, required this.product});

  @override
  State<AddonSelector> createState() => _AddonSelectorState();
}

class _AddonSelectorState extends State<AddonSelector> {
  final Map<String, int> selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    for (var addon in widget.addons) {
      selectedQuantities[addon.id] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoryService>(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final surface = AppSurface.of(context);
        return Container(
          decoration: BoxDecoration(
            color: surface.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Product header
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedImage(
                          url: widget.product.image,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          memCacheWidth: 144,
                        ),
                      ),
                    ),
                    AppSpacing.w10,
                    Expanded(
                      child: Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: surface.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: surface.border),

              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "Choose your add-ons",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: surface.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Scrollable list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.addons.length,
                  itemBuilder: (context, index) {
                    final addon = widget.addons[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CachedImage(
                            url: addon.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            memCacheWidth: 100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addon.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: surface.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "₹${addon.price.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: surface.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (addon.slashedPrice > addon.price)
                                      Text(
                                        "₹${addon.slashedPrice.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontSize: 13,
                                          color: surface.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              activeColor: AppColor.primary,
                              value: provider.selectedProduct.any(
                                (product) => product.id == addon.id,
                              ),
                              onChanged: (v) {
                                if (!provider.selectedProduct.any(
                                  (product) => product.id == addon.id,
                                )) {
                                  provider.addProduct(context, addon);
                                } else {
                                  provider.removeProductCount(addon.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Fixed "View Cart" button
              SafeArea(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, AppPageRoutes.cart());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    height: 70,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColor.primary,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Addon thumbnails
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.selectedProduct.length,
                            itemBuilder: (context, index) {
                              return Transform.translate(
                                offset: Offset(-index * 40, 0),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: CachedImage(
                                      url: provider.selectedProduct[index].image,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 80,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Cart label
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'View cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${provider.selectedProduct.length} ITEMS",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.w20,
                        Text(
                          "₹${provider.getTotalAmount(0, 0, platformFee: 0, handlingCharge: 0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppSpacing.h15,
            ],
          ),
        );
      },
    );
  }
}
