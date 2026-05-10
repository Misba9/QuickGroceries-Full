import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/services/rating_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddRatingScreen extends StatefulWidget {
  const AddRatingScreen({super.key, required this.product});
  final ProductModel product;

  @override
  State<AddRatingScreen> createState() => _AddRatingScreenState();
}

class _AddRatingScreenState extends State<AddRatingScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RatingService>(context);
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Column(
        children: [
          PrimaryAppBar(isBackButton: true),
          AppSpacing.h20,
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                WrapperWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColor.primary),
                          AppSpacing.w10,
                          Text(
                            'Add Product Rating',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      Divider(color: Colors.grey.shade300),
                      AppSpacing.h20,
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Product Name'),
                              AppSpacing.h10,
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  widget.product.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.w20,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Product ID'),
                              AppSpacing.h10,
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  widget.product.id,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Name *'),
                          AppSpacing.h10,
                          SizedBox(
                            width: MediaQuery.of(context).size.width * .4,
                            child: PrimaryTextField(
                              controller: provider.userNameController,
                              hintText: 'Enter user name',
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rating *'),
                          AppSpacing.h10,
                          Row(
                            children: List.generate(5, (index) {
                              int starIndex = index + 1;
                              return GestureDetector(
                                onTap: () {
                                  provider.setRating(starIndex.toDouble());
                                },
                                child: Icon(
                                  starIndex <= provider.selectedRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: starIndex <= provider.selectedRating
                                      ? Colors.amber
                                      : Colors.grey,
                                  size: 40,
                                ),
                              );
                            }),
                          ),
                          AppSpacing.h10,
                          if (provider.selectedRating > 0)
                            Text(
                              'Selected: ${provider.selectedRating} / 5',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.h20,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review *'),
                          AppSpacing.h10,
                          TextFormField(
                            controller: provider.reviewController,
                            maxLines: 5,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: 'Enter review text',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SizedBox(
                      height: 40,
                      width: 300,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => provider.addRating(
                          context,
                          widget.product.id,
                          widget.product.name,
                        ),
                        child: provider.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 1,
                                ),
                              )
                            : Text('Submit Rating'),
                      ),
                    ),
                  ),
                ),
                AppSpacing.h20,
                AppSpacing.h20,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

