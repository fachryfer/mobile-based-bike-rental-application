import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rental_sepeda/utils/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi berhasil! Silakan login.'), backgroundColor: Colors.green),
          );
        }
        Navigator.pushReplacementNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage ?? 'Registrasi gagal'), backgroundColor: Colors.red),
          );
        }
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
                      Icon(Icons.person_add, size: 100, color: AppColors.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Bergabunglah dengan Kami!',
                        style: AppTextStyles.headline1.copyWith(color: AppColors.textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daftar dan mulai petualangan sepedamu.',
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
                        controller: _nameController,
                        decoration: AppDecorations.inputDecoration.copyWith(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person, color: AppColors.primaryColor)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                        style: AppTextStyles.bodyText,
                      ),
                      const SizedBox(height: 16),
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
                        validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                        style: AppTextStyles.bodyText,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Daftar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          textStyle: AppTextStyles.buttonText.copyWith(fontWeight: FontWeight.normal),
                        ),
                        child: const Text('Sudah punya akun? Login'),
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