import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';

class CustomerDetailsAddScreen extends StatefulWidget {
  const CustomerDetailsAddScreen({super.key});

  @override
  State<CustomerDetailsAddScreen> createState() =>
      _CustomerDetailsAddScreenState();
}

class _CustomerDetailsAddScreenState extends State<CustomerDetailsAddScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      await auth.hydrateProfileFromCache();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final complete =
            await UserProfileRepository().isProfileComplete(uid);
        if (complete && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LandingScreen()),
          );
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthService>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Complete your profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              AppSpacing.h10,
              Text(
                'One-time setup — edit anytime from Profile.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              AppSpacing.h20,
              Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CircleAvatar(
                        backgroundImage: provider.image != null
                            ? FileImage(provider.image!)
                            : null,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: provider.pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.h20,
              TextFormField(
                controller: provider.nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.h15,
              TextFormField(
                controller: provider.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.h20,
              TextFormField(
                controller: provider.referralCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Referral code (optional)',
                  hintText: 'e.g. AHMED123',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.h15,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender'),
                  AppSpacing.h10,
                  Row(
                    children: [
                      Expanded(
                        child: _GenderChip(
                          label: 'Male',
                          icon: Icons.male,
                          selected: provider.selectedGender == 'male',
                          onTap: () => provider.setGender('male'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _GenderChip(
                          label: 'Female',
                          icon: Icons.female,
                          selected: provider.selectedGender == 'female',
                          onTap: () => provider.setGender('female'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Continue',
                onTap: () => provider.registerUser(context),
                isLoading: provider.isLoading,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColor.primary : Colors.grey,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? AppColor.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColor.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColor.primary : Colors.grey,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
