import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  Future<void> _addCoupon() async {
    if (_couponController.text.isNotEmpty &&
        _discountController.text.isNotEmpty) {
      await _firestore.collection('coupons').add({
        'code': _couponController.text.trim(),
        'discount': int.tryParse(_discountController.text) ?? 0,
        'createdAt': Timestamp.now(),
      });
      _couponController.clear();
      _discountController.clear();
    }
  }

  Future<void> _deleteCoupon(String id) async {
    await _firestore.collection('coupons').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pad = adminResponsivePadding(w);
        final narrow = adminIsMobileWidth(w);
        final fieldMax = (w - pad * 2).clamp(120.0, 420.0);

        return ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PrimaryAppBar(),
                    AppSpacing.h20,
                    WrapperWidget(
                      child: narrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PrimaryTextField(
                                  controller: _couponController,
                                  hintText: 'Coupon Code',
                                ),
                                AppSpacing.h10,
                                PrimaryTextField(
                                  controller: _discountController,
                                  hintText: 'Discount in (%)',
                                ),
                                AppSpacing.h10,
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: AppColor.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _addCoupon(),
                                    child: isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 1,
                                            ),
                                          )
                                        : const Text('Submit'),
                                  ),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: fieldMax,
                                  child: PrimaryTextField(
                                    controller: _couponController,
                                    hintText: 'Coupon Code',
                                  ),
                                ),
                                SizedBox(
                                  width: fieldMax.clamp(120, 280),
                                  child: PrimaryTextField(
                                    controller: _discountController,
                                    hintText: 'Discount in (%)',
                                  ),
                                ),
                                SizedBox(
                                  height: 44,
                                  width: 120,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: AppColor.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _addCoupon(),
                                    child: isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 1,
                                            ),
                                          )
                                        : const Text('Submit'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    AppSpacing.h20,
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('coupons')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final coupons = snapshot.data!.docs;

                        if (coupons.isEmpty) {
                          return const Center(
                            child: Text('No coupons available'),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: coupons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final coupon = coupons[index];
                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(
                                  'Code: ${coupon['code']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Discount: ${coupon['discount']}%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCoupon(coupon.id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
