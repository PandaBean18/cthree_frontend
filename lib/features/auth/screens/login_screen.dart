import 'package:flutter/material.dart';
import 'package:cthree/features/shared/widgets/app_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12151C), // Background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: CustomScrollView( // Better for smoothness than SingleChildScrollView
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                     Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                            "WELCOME",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                        ), 
                        SizedBox(width: 8,),
                        Text(
                          "BACK",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic
                            ),

                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You've been missed!",
                      style: TextStyle(color: Color(0xFF6F7685), fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Input Fields
                    _buildInputLabel("Email Address"),
                    _buildTextField(_emailController, "Enter your email", Icons.alternate_email),
                    
                    const SizedBox(height: 24),
                    
                    _buildInputLabel("Password"),
                    _buildTextField(_passwordController, "••••••••", Icons.lock_outline, isPassword: true),
                    
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF45A2FF))),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Primary Login Action
                    AppButton(
                      text: "Log In",
                      isLoading: _isLoading,
                      onPressed: () {
                        // Logic for Rails API login
                      },
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFF1E222A), thickness: 2)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OR", style: TextStyle(color: Color(0xFF6F7685))),
                        ),
                        Expanded(child: Divider(color: Color(0xFF1E222A), thickness: 2)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Social Logins
                    AppButton(
                      variant: ButtonVariant.outline,
                      text: "Continue with Google",
                      icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white), // Replace with asset later
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      variant: ButtonVariant.outline,
                      text: "Continue with Apple",
                      icon: const Icon(Icons.apple, size: 24),
                      onPressed: () {},
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF6F7685))),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Sign Up", style: TextStyle(color: Color(0xFFE157A4))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6F7685)),
        prefixIcon: Icon(icon, color: const Color(0xFF6F7685), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E222A), // Surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF45A2FF), width: 1),
        ),
      ),
    );
  }
}