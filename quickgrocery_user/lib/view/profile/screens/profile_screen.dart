import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/services/language_service.dart';
import 'package:quickgrocery/view/address/screens/address_screen.dart';
import 'package:quickgrocery/view/auth/screens/login_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/view/profile/screens/support_screen.dart';
import 'package:quickgrocery/view/notifications/notification_center_screen.dart';
import 'package:quickgrocery/view/wishlist/screens/wishlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_spacing.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notification = true;
  String? userGender;

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  Future<void> _loadGender() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      userGender = pref.getString('user_gender');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        Provider.of<HomeProvider>(context, listen: false).onSelectedChange(0);
        return false; // Prevent default back navigation
      },
      child: Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<HomeProvider>(context, listen: false).getCustomer();
          },
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        height: 80,
                        width: 80,
                        child: CircleAvatar(
                          backgroundImage: provider.customer!.image == ''
                              ? null
                              : NetworkImage(provider.customer!.image),
                          backgroundColor: Colors.grey.shade200,
                          child: provider.customer!.image == ''
                              ? (userGender == 'female'
                                    ? Image.asset('assets/icons/woman.png')
                                    : Image.asset('assets/icons/man.png'))
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.h10,
                Center(
                  child: Text(
                    provider.customer!.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                AppSpacing.h20,
                AppSpacing.h20,
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'general'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.h20,
                      ProfileTile(
                        icon: 'assets/icons/people.png',
                        label: provider.customer!.name,
                      ),
                      AppSpacing.h10,
                      Divider(color: Colors.grey.shade300),
                      AppSpacing.h10,
                      GestureDetector(
                        onTap: () {
                          //  p.init();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddressScreen(),
                            ),
                          );
                        },
                        child: ProfileTile(
                          icon: 'assets/icons/home-address.png',
                          label: 'my_address'.tr(),
                        ),
                      ),
                      AppSpacing.h10,
                      Divider(color: Colors.grey.shade300),
                      AppSpacing.h10,
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WishlistScreen(),
                            ),
                          );
                        },
                        child: ProfileTile(
                          icon: 'assets/icons/heart.png',
                          label: 'wishlist'.tr(),
                        ),
                      ),
                      AppSpacing.h10,
                      Divider(color: Colors.grey.shade300),
                      AppSpacing.h10,
                      ProfileTile(
                        icon: 'assets/icons/iphone.png',
                        label: "+91${provider.customer!.phoneNumber}",
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'notifications'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.h20,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 25,
                                width: 25,
                                child: Image.asset(
                                  'assets/icons/chat.png',
                                  color: AppColor.primary,
                                ),
                              ),
                              AppSpacing.w10,
                              Text(
                                'push_notifications'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          CupertinoSwitch(
                            activeColor: AppColor.primary,
                            value: notification,
                            onChanged: (v) {
                              notification = !notification;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      AppSpacing.h10,
                      Divider(color: Colors.grey.shade300),
                      AppSpacing.h10,
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  const NotificationCenterScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: ProfileTile(
                                icon: 'assets/icons/chat.png',
                                label: 'notification_center'.tr(),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) {
                                  return const SizedBox.shrink();
                                }
                                return StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('customers')
                                      .doc(uid)
                                      .collection('notification_inbox')
                                      .where('read', isEqualTo: false)
                                      .snapshots(),
                                  builder: (context, snap) {
                                    final n = snap.data?.docs.length ?? 0;
                                    if (n == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        n > 99 ? '99+' : '$n',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
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
                    ],
                  ),
                ),
                AppSpacing.h20,
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'language'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.h20,
                      Consumer<LanguageService>(
                        builder: (context, languageService, _) {
                          return Column(
                            children: languageService
                                .getAvailableLanguages()
                                .map((lang) {
                                  final isSelected =
                                      languageService
                                          .currentLocale
                                          .languageCode ==
                                      lang['code'];
                                  return GestureDetector(
                                    onTap: () async {
                                      await languageService.changeLanguage(
                                        Locale(
                                          lang['code'] as String,
                                          lang['country'] as String,
                                        ),
                                        context,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColor.primary
                                              : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        color: isSelected
                                            ? AppColor.primary.withOpacity(0.1)
                                            : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? AppColor.primary
                                                : Colors.grey,
                                          ),
                                          AppSpacing.w10,
                                          Text(
                                            lang['name'] as String,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? AppColor.primary
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'support'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.h20,
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportScreen(),
                            ),
                          );
                        },
                        child: ProfileTile(
                          icon: 'assets/icons/support.png',
                          label: 'support'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
                // AppSpacing.h20,
                // Container(
                //   width: MediaQuery.of(context).size.width,
                //   padding: const EdgeInsets.all(6),
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.grey.shade300),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       ListTile(
                //         onTap: () async {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) => const ReferScreen(),
                //             ),
                //           );
                //           // p.shareReferralLink(
                //           //     FirebaseAuth.instance.currentUser!.uid);
                //         },
                //         leading: Icon(Icons.share, color: AppColor.primary),
                //         title: const Text('Refer & Earn a Free Burger! 🍔'),
                //         subtitle: Text(
                //           'Invite 3 friends & get 1 burger absolutely FREE! ',
                //           style: TextStyle(fontSize: 12, color: Colors.grey),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                AppSpacing.h20,
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (Route<dynamic> route) =>
                                false, // This condition removes all previous routes.
                          );
                        },
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text('logout'.tr()),
                      ),
                    ],
                  ),
                ),

                // AppSpacing.h20,
                // Container(
                //   width: MediaQuery.of(context).size.width,
                //   padding: const EdgeInsets.all(15),
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.grey.shade300),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         'Legal',
                //         style: TextStyle(
                //             fontSize: 16, fontWeight: FontWeight.bold),
                //       ),
                //       AppSpacing.h20,
                //       const ProfileTile(
                //           icon: 'assets/icons/file (1).png',
                //           label: 'Privacy policy'),
                //       AppSpacing.h10,
                //       Divider(color: Colors.grey.shade300),
                //       AppSpacing.h10,
                //       const ProfileTile(
                //           icon: 'assets/icons/file (2).png',
                //           label: 'Terms and conditions')
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 25,
          width: 25,
          child: Image.asset(icon, color: AppColor.primary),
        ),
        AppSpacing.w10,
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
