import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/view/profile/domain/profile_models.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Edit name, email, and profile photo.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final ProfileData profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  File? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.customer.name);
    _email = TextEditingController(text: widget.profile.customer.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final updates = <String, dynamic>{
        'name': _name.text.trim(),
        'email': _email.text.trim(),
      };

      if (_pickedImage != null) {
        final auth = Provider.of<AuthService>(context, listen: false);
        final url = await auth.uploadImageToStorage(_pickedImage!);
        updates['profile_image'] = url;
      }

      await UserProfileRepository().saveProfile(
        uid: uid,
        fields: updates,
      );

      final home = Provider.of<HomeProvider>(context, listen: false);
      home.customer = null;
      await home.getCustomer();

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.success('Profile updated', context: context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error('Could not save profile: $e', context: context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.profile.customer.image;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  ClipOval(
                    child: _pickedImage != null
                        ? Image.file(
                            _pickedImage!,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          )
                        : imageUrl.isNotEmpty
                            ? CachedImage(
                                url: imageUrl,
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                                memCacheWidth: 208,
                              )
                            : ColoredBox(
                                color: AppSurface.of(context).subtle,
                                child: const SizedBox(
                                  width: 104,
                                  height: 104,
                                  child: Icon(Icons.person, size: 48),
                                ),
                              ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: AppLoading.micro)
                : Text(
                    'Save changes',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}
