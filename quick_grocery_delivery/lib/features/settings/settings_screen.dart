import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_session_prefs.dart';
import 'package:quick_grocery_delivery/features/login/force_password_change_screen.dart';
import 'package:quick_grocery_delivery/features/login/forgot_password/forgot_password_email_screen.dart';
import 'package:quick_grocery_delivery/features/login/login_screen.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      _notifications = pref.getBool('driver_notifications') ?? true;
      _darkMode = pref.getBool('driver_dark_mode') ?? false;
    });
  }

  Future<void> _setNotifications(bool v) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('driver_notifications', v);
    setState(() => _notifications = v);
  }

  Future<void> _setDarkMode(bool v) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('driver_dark_mode', v);
    setState(() => _darkMode = v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restart app to apply theme')),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<LoginService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _logoutAllDevices() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ask admin to use “Force logout” from Delivery Boys security'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push notifications'),
            subtitle: const Text('New orders, payments, incentives'),
            value: _notifications,
            onChanged: _setNotifications,
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: const Text('English'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            onTap: () async {
              final id = await DeliverySessionPrefs.deliveryBoyId();
              if (id == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForcePasswordChangeScreen(partnerId: id),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Forgot password'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordEmailScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_other_outlined),
            title: const Text('Logout all devices'),
            onTap: _logoutAllDevices,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
