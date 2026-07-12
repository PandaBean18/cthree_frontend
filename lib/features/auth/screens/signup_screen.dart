import 'package:flutter/material.dart';
import 'package:cthree/features/shared/widgets/app_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cthree/core/api/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12151C), // Background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: CustomScrollView(
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
                            "CREATE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                        ), 
                        SizedBox(width: 8,),
                        Text(
                          "ACCOUNT",
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
                      "Join the platform today!",
                      style: TextStyle(color: Color(0xFF6F7685), fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Input Fields
                    _buildInputLabel("Username"),
                    _buildTextField(_usernameController, "Enter your username", Icons.person_outline),

                    const SizedBox(height: 16),

                    _buildInputLabel("Email Address"),
                    _buildTextField(_emailController, "Enter your email", Icons.alternate_email),

                    const SizedBox(height: 16),

                    _buildInputLabel("Description / Bio"),
                    _buildTextField(_descriptionController, "Tell us about yourself", Icons.info_outline),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputLabel("Password"),
                    _buildTextField(_passwordController, "••••••••", Icons.lock_outline, isPassword: true),
                    
                    const SizedBox(height: 32),

                    // Primary Signup Action
                    AppButton(
                      text: "Sign Up",
                      isLoading: _isLoading,
                      onPressed: () async {
                        if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _usernameController.text.isEmpty || _descriptionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields")),
                          );
                          return;
                        }
                        
                        final messenger = ScaffoldMessenger.of(context);

                        setState(() {
                          _isLoading = true;
                        });

                        final success = await context.read<AuthProvider>().signup(
                          _emailController.text.trim(),
                          _passwordController.text,
                          _usernameController.text.trim(),
                          _descriptionController.text.trim()
                        );

                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }

                        if (!success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text("Sign up failed. Please try again."),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
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
                      icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white),
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
                        const Text("Already have an account? ", style: TextStyle(color: Color(0xFF6F7685))),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Log In", style: TextStyle(color: Color(0xFFE157A4))),
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
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6F7685)),
        prefixIcon: Icon(icon, color: const Color(0xFF6F7685), size: 20),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6F7685),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
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
