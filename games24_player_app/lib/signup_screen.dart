import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'main_layout.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _selectedSportIndex = 0; // 0: Football, 1: Cricket, 2: Badminton
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  String _selectedCountryCode = '+91';

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.withOpacity(0.06),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontFamily: 'PrimeNordic',
                        fontSize: 32, // slightly larger for display font
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join thousands of players booking turfs\ndaily',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: 'e.g. Alex Hunter',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // Mobile Number Field
              _buildLabel('Mobile Number'),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCountryCode = newValue;
                              });
                            }
                          },
                          items: _countryCodes.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            suffixIcon: Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF), size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Password'),
                  const Text(
                    'Must be secure',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                hintText: 'Create password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Preferred Sport
              _buildLabel('Preferred Sport'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSportCard(0, Icons.sports_soccer, 'Football'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSportCard(1, Icons.sports_cricket, 'Cricket'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSportCard(2, Icons.sports_tennis, 'Badminton'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Terms Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      activeColor: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w500),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w500),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainLayout()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // OR Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              ),
              const SizedBox(height: 24),

              // Social Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      'Google',
                      'assets/images/google_icon.png', // We'll just use flutter icon if asset not available, let's use built in or text, wait, better use something that works.
                      Icons.g_mobiledata, // Fallback
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(
                      'Apple',
                      'assets/images/apple_icon.png',
                      Icons.apple, // Fallback
                      Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 52,
      child: TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.greenAccent.shade400, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }



  Widget _buildSportCard(int index, IconData icon, String label) {
    final isSelected = _selectedSportIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSportIndex = index;
        });
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green.shade600 : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.green.shade600 : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, String imagePath, IconData fallbackIcon, Color iconColor) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Assuming image assets are not present, use Icon as fallback
            Icon(fallbackIcon, size: 24, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
