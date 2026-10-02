import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

import '../../domain/order_models.dart';

/// Shown when an order is delivered — success animation + rating CTAs.
class DeliveredCelebration extends StatelessWidget {
  const DeliveredCelebration({
    super.key,
    required this.order,
    required this.onRateRider,
    required this.onRateVendor,
  });

  final LiveOrder order;
  final VoidCallback onRateRider;
  final VoidCallback onRateVendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withValues(alpha: 0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Lottie.asset(
              'assets/lottie/success.json',
              repeat: false,
            ),
          ),
          Text(
            'Order delivered!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hope you enjoy your groceries.',
            style: GoogleFonts.poppins(
              color: AppSurface.of(context).textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RateButton(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Rate delivery partner',
                  onTap: onRateRider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RateButton(
                  icon: Icons.storefront_rounded,
                  label: 'Rate vendor',
                  onTap: onRateVendor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppSurface.of(context).border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColor.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for star ratings (delivery partner or vendor).
Future<void> showOrderRatingSheet({
  required BuildContext context,
  required String orderId,
  required String title,
  required String firestoreField,
}) async {
  var rating = 0.0;
  final reviewController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 34,
                        ),
                        onPressed: () {
                          setModalState(() => rating = index + 1.0);
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: rating < 1
                          ? null
                          : () async {
                              await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(orderId)
                                  .set(
                                {
                                  firestoreField: rating,
                                  '${firestoreField}_review':
                                      reviewController.text.trim(),
                                  if (firestoreField == 'star') 'is_rated': true,
                                },
                                SetOptions(merge: true),
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Submit rating',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  reviewController.dispose();
}
