import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _loadingAction;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handle(String action, Future<bool> Function() call) async {
    setState(() => _loadingAction = action);
    final ok = await call();
    if (!mounted) return;
    setState(() => _loadingAction = null);

    if (ok) {
      context.go('/home');
    } else {
      final message = ref.read(authControllerProvider.notifier).errorMessage ??
          'Something went wrong. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(authControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.primaryGradient,
                ).createShader(bounds),
                child: Text(
                  'TBVOY',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Small Actions. Big Transformation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) return 'At least 8 characters';
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AuthButton(
                      label: 'Sign In',
                      isPrimary: true,
                      isLoading: _loadingAction == 'email',
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        _handle(
                          'email',
                          () => controller.signInWithEmail(
                            _emailController.text.trim(),
                            _passwordController.text,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('or continue with', style: theme.textTheme.bodyMedium),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSpacing.lg),

              AuthButton(
                label: 'Continue with Google',
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                isLoading: _loadingAction == 'google',
                onPressed: () => _handle('google', controller.signInWithGoogle),
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: AppSpacing.md),
                AuthButton(
                  label: 'Continue with Apple',
                  icon: const Icon(Icons.apple_rounded, size: 22),
                  isLoading: _loadingAction == 'apple',
                  onPressed: () => _handle('apple', controller.signInWithApple),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AuthButton(
                label: 'Continue as Guest',
                icon: const Icon(Icons.person_outline_rounded),
                isLoading: _loadingAction == 'guest',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _handle('guest', controller.signInAnonymously);
                },
              ),

              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
