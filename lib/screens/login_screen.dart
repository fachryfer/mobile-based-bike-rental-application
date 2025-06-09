import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rental_sepeda/utils/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
        final role = userDoc.data()?['role'] ?? 'user';
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else {
          Navigator.pushReplacementNamed(context, '/user_home');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: AppDecorations.cardDecoration,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.pedal_bike, size: 100, color: AppColors.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Selamat Datang di Rental Sepeda!',
                        style: AppTextStyles.headline1.copyWith(color: AppColors.textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temukan perjalananmu yang sempurna.',
                        style: AppTextStyles.subtitle.copyWith(color: AppColors.subtitleColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.dangerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(_errorMessage!, style: AppTextStyles.bodyText.copyWith(color: AppColors.dangerColor), textAlign: TextAlign.center),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: AppDecorations.inputDecoration.copyWith(labelText: 'Email', prefixIcon: Icon(Icons.email, color: AppColors.primaryColor)),
                        validator: (value) => value == null || value.isEmpty ? 'Email wajib diisi' : null,
                        style: AppTextStyles.bodyText,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: AppDecorations.inputDecoration.copyWith(labelText: 'Password', prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor)),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty ? 'Password wajib diisi' : null,
                        style: AppTextStyles.bodyText,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          textStyle: AppTextStyles.buttonText.copyWith(fontWeight: FontWeight.normal),
                        ),
                        child: const Text('Belum punya akun? Daftar'),
                      ),
                    ],
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