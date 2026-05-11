import 'dart:ui';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/auth/services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Premium split login — branding left, Firebase email/password right.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const slogan = 'Manage your grocery business smarter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isCompact = w < 720;
          final isTablet = w >= 720 && w < 1024;

          if (isCompact) {
            return _MobileLoginLayout();
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: isTablet ? 5 : 6,
                child: const _BrandingPanel(compact: false),
              ),
              Expanded(
                flex: isTablet ? 6 : 5,
                child: _LoginFormPanel(maxFormWidth: isTablet ? 380.0 : 420.0),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileLoginLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: const _BrandingPanel(compact: true, slogan: LoginScreen.slogan),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: _LoginFormCard(maxFormWidth: double.infinity),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({required this.compact, this.slogan});

  final bool compact;
  final String? slogan;

  @override
  Widget build(BuildContext context) {
    final sloganText = slogan ?? LoginScreen.slogan;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9F2),
            Color(0xFFFFF3E0),
            Color(0xFFFFEFD5),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Blob(
            top: compact ? -20 : 40,
            right: compact ? -40 : -20,
            size: 180,
            opacity: 0.14,
          ),
          _Blob(
            bottom: compact ? 10 : 80,
            left: compact ? -50 : -30,
            size: 220,
            opacity: 0.1,
          ),
          _Blob(
            top: compact ? 120 : 200,
            left: compact ? 20 : 60,
            size: 100,
            opacity: 0.12,
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'quick_grocery_login_logo',
                    child: _LogoBlock(compact: compact),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.94, 0.94),
                        duration: 550.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  SizedBox(height: compact ? 16 : 28),
                  Text(
                    sloganText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 450.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                  if (!compact) ...[
                    const SizedBox(height: 36),
                    const _GroceryIllustrationRow()
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 500.ms),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final drift = size < 150 ? 6.0 : 12.0;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.primary.withValues(alpha: opacity),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: drift,
              duration: 4.seconds,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = compact
            ? (c.maxWidth * 0.42).clamp(120.0, 200.0)
            : (c.maxWidth * 0.38).clamp(180.0, 320.0);
        return Material(
          color: Colors.transparent,
          elevation: compact ? 12 : 24,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: side,
                height: side,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.25),
                    ],
                  ),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.storefront_rounded,
                    size: side * 0.45,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroceryIllustrationRow extends StatelessWidget {
  const _GroceryIllustrationRow();

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, Color bg) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Icon(icon, size: 26, color: Colors.brown.shade800),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 5, duration: 2.5.seconds, curve: Curves.easeInOut);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(Icons.shopping_basket_outlined, AppColor.primary),
        const SizedBox(width: 20),
        chip(Icons.local_shipping_outlined, const Color(0xFFFFE082)),
        const SizedBox(width: 20),
        chip(Icons.eco_outlined, const Color(0xFFC8E6C9)),
      ],
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({required this.maxFormWidth});

  final double maxFormWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAF8),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          child: _LoginFormCard(maxFormWidth: maxFormWidth),
        ),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({required this.maxFormWidth});

  final double maxFormWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxFormWidth.isFinite ? maxFormWidth : 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.92),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign in',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quick Grocery admin',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 28),
                Consumer<LoginService>(
                  builder: (context, provider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginInput(
                          label: 'Email',
                          controller: provider.emailController,
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        _LoginInput(
                          label: 'Password',
                          controller: provider.passwordController,
                          hint: 'Enter password',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                        ),
                        const SizedBox(height: 28),
                        _GradientLoginButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => provider.signIn(context),
                          loading: provider.isLoading,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 22, color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFFF7F7F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientLoginButton extends StatefulWidget {
  const _GradientLoginButton({
    required this.onPressed,
    required this.loading,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<_GradientLoginButton> createState() => _GradientLoginButtonState();
}

class _GradientLoginButtonState extends State<_GradientLoginButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover && widget.onPressed != null && !widget.loading ? 1.02 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primary,
                      Color.lerp(AppColor.primary, Colors.white, 0.22)!,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: _hover ? 0.45 : 0.28),
                      blurRadius: _hover ? 22 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: widget.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF3D3D3D),
                          ),
                        )
                      : Text(
                          'Sign in',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
