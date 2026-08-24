import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().signUp(
        fullName: _name.text,
        email: _email.text,
        mobile: _mobile.text,
        password: _password.text,
      );

      if (!mounted) return;

      showAppSnackBar(
        context,
        'Account created successfully.',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message = 'Unable to create account.';

      switch (error.code) {
        case 'email-already-in-use':
          message = 'This email already has an account.';
          break;

        case 'invalid-email':
          message = 'Enter a valid email address.';
          break;

        case 'weak-password':
          message = 'Use a stronger password.';
          break;

        case 'network-request-failed':
          message = 'Check your internet connection.';
          break;

        case 'operation-not-allowed':
          message = 'Email and password sign-up is not enabled.';
          break;

        default:
          message = error.message ?? message;
      }

      showAppSnackBar(context, message);
    } catch (error) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        'Something went wrong. Please try again.',
      );

      debugPrint('Sign-up error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'Create Account',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SmileHubLogo(),
                const SizedBox(height: 22),

                Text(
                  'Join SmileHub',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Create your dental supplies buyer account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.name,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your full name';
                    }

                    if (value.trim().length < 2) {
                      return 'Enter a valid full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Enter your email address';
                    }

                    final emailPattern = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailPattern.hasMatch(email)) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.telephoneNumber,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                  validator: (value) {
                    final mobile = value
                            ?.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            ) ??
                        '';

                    if (mobile.length < 10) {
                      return 'Enter a valid mobile number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a password';
                    }

                    if (value.length < 6) {
                      return 'Use at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _createAccount();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(
                      Icons.lock_reset_rounded,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password';
                    }

                    if (value != _password.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed:
                      _isLoading ? null : _createAccount,
                  child: Text(
                    _isLoading
                        ? 'Creating account...'
                        : 'Create Account',
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text(
                    'Already have an account? Log in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}