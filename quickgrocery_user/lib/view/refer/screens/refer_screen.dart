import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/profile/services/profile_service.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ProfileService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Refer & Earn')),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Text('Your Referal', style: TextStyle(fontSize: 16)),
                  AppSpacing.h20,
                  FutureBuilder<double>(
                    future: p.getReferralProgress(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();

                      double progress = snapshot.data!;
                      int completedReferrals = (progress * 3)
                          .toInt(); // Convert progress to count

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            color: AppColor.primary,
                          ),
                          AppSpacing.h15,
                          Text(
                            "Referrals Completed: $completedReferrals / 3",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.h20,
            Container(
              padding: EdgeInsets.all(15),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Text(
                "Terms and Conditions:\n\n"
                "1. You must share your referral link with 3 friends.\n"
                "2. Each referred friend must make a purchase of ₹500 or more.\n"
                "3. Once all 3 referrals are completed, you will earn 1 successful referral reward.\n"
                "4. After completing 3 successful referrals, you can claim a free burger.\n"
                "5. The reward can only be redeemed once per user for every 3 completed referrals.\n"
                "6. This offer is subject to availability and may change at any time without prior notice.\n"
                "7. Fraudulent or self-referrals will not be counted.\n\n"
                "Enjoy referring and earn your free burger! 🍔🔥",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            AppSpacing.h20,
            Spacer(),
            PrimaryButton(
              label: 'Refer the link',
              onTap: () {
                p.shareReferralLink(FirebaseAuth.instance.currentUser!.uid);
              },
            ),
          ],
        ),
      ),
    );
  }
}
