import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

class CartProductCard extends StatelessWidget {
  const CartProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.quantity,
    required this.amount,
    required this.onRemove,
    required this.onAdd,
  });
  final String image;
  final String name;
  final String quantity;
  final String amount;
  final Function() onRemove;
  final Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedImage(
                  url: image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  memCacheWidth: 160,
                ),
              ),
              AppSpacing.w15,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .40,
                    child: Text(
                      name,
                      maxLines: 2,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  AppSpacing.h5,
                  Text(
                    quantity,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  AppSpacing.h5,
                  Text(
                    amount,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.primary),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.remove, color: AppColor.primary),
                ),
                AppSpacing.w10,
                Text(
                  quantity,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                AppSpacing.w10,
                GestureDetector(
                  onTap: onAdd,
                  child: const Icon(Icons.add, color: AppColor.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
