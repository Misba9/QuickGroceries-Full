import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryAppBar(),
            AppSpacing.h20,
            WrapperWidget(
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 3,
                        child: PrimaryTextField(
                          controller: _couponController,
                          hintText: 'Coupon Code',
                        ),
                      ),
                      AppSpacing.w20,
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 3,
                        child: PrimaryTextField(
                          controller: _discountController,
                          hintText: 'Discount in (%)',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: SizedBox(
                          height: 40,
                          width: 100,
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
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 1,
                                    ),
                                  )
                                : Text('Submit'),
                          ),
                        ),
                      ),
                    ],
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
                  return const Center(child: CircularProgressIndicator());
                }
                var coupons = snapshot.data!.docs;

                if (coupons.isEmpty) {
                  return const Center(child: Text('No coupons available'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    var coupon = coupons[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Code: ${coupon['code']}'),
                        subtitle: Text('Discount: ${coupon['discount']}%'),
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
    );
  }
}
