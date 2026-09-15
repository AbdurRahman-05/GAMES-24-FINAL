import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // State variables
  int _currentStep = 1;
  String _selectedVerification = 'whatsapp';
  
  // Password step states
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  // OTP logic state
  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Step 3 finished -> Reset complete, return to login
      Navigator.pop(context);
      // Optional: show a success snackbar here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.withOpacity(0.06),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Custom Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF4B5563)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (_currentStep > 1) {
                          setState(() {
                            _currentStep--;
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontFamily: 'PrimeNordic',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SECURE',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Logo with Shield
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 72,
                          width: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Headings
                const Text(
                  'Recover Your Account',
                  style: TextStyle(
                    fontFamily: 'PrimeNordic',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Follow 3 simple steps to verify your contact and update your secure password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stepper
                _buildStepper(),
                const SizedBox(height: 24),

                // Main Form Card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey<int>(_currentStep),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep == 1) _buildStep1Contact(),
                        if (_currentStep == 2) _buildStep2OTP(),
                        if (_currentStep == 3) _buildStep3Password(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Back to Login
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Remember password? Back to Log In',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Footer SSL
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: Color(0xFF9CA3AF)),
                    SizedBox(width: 6),
                    Text(
                      '256-bit SSL Encrypted • GAMES24 Secure Authentication',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Contact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.badge_outlined, color: Colors.green.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Account Identifier',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Where should we send your OTP?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF3F4F6), height: 1),
        const SizedBox(height: 20),

        // Input Field
        const Text(
          'Registered Email or Mobile Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'striker99@mail.com',
            hintStyle: const TextStyle(color: Color(0xFF111827)),
            prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green.shade500, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Verification Options
        const Text(
          'Send verification via:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRadioOption(
                id: 'whatsapp',
                icon: Icons.chat_outlined,
                label: 'WhatsApp / SMS',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioOption(
                id: 'email',
                icon: Icons.email_outlined,
                label: 'Direct Email',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Button
        _buildActionButton(
          label: 'Send Verification Code',
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildStep2OTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.password_outlined, color: Colors.green.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Verification Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
                      children: [
                        const TextSpan(text: 'Enter the 4-digit code sent to your '),
                        TextSpan(
                          text: _selectedVerification == 'whatsapp' ? 'WhatsApp/SMS' : 'Email',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF3F4F6), height: 1),
        const SizedBox(height: 24),

        // OTP Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 56,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade500, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 3) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Button
        _buildActionButton(
          label: 'Verify Code',
          onPressed: _nextStep,
        ),
        const SizedBox(height: 16),

        // Resend
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              children: [
                const TextSpan(text: "Didn't receive code? "),
                TextSpan(
                  text: 'Resend in 30s',
                  style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Password() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_reset_outlined, color: Colors.green.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3. Secure Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a new strong password.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF3F4F6), height: 1),
        const SizedBox(height: 20),

        // New Password Field
        const Text(
          'New Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(
          hintText: 'Enter new password',
          obscureText: _obscureNew,
          onToggle: () {
            setState(() {
              _obscureNew = !_obscureNew;
            });
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password Field
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(
          hintText: 'Confirm new password',
          obscureText: _obscureConfirm,
          onToggle: () {
            setState(() {
              _obscureConfirm = !_obscureConfirm;
            });
          },
        ),
        const SizedBox(height: 24),

        // Button
        _buildActionButton(
          label: 'Update Password',
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF9CA3AF),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green.shade500, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(1, 'Contact'),
          _buildStepDivider(1),
          _buildStep(2, 'OTP Code'),
          _buildStepDivider(2),
          _buildStep(3, 'Password'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label) {
    bool isActive = _currentStep == number;
    bool isCompleted = _currentStep > number;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? Colors.green.shade600 : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted 
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isActive || isCompleted ? Colors.green.shade600 : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepAfter) {
    bool isCompleted = _currentStep > stepAfter;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24), // Offset to align with circles
        height: 2,
        color: isCompleted ? Colors.green.shade600 : const Color(0xFFF3F4F6),
      ),
    );
  }

  Widget _buildRadioOption({
    required String id,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedVerification == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVerification = id;
        });
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.02) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : const Color(0xFFE5E7EB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green.shade600 : const Color(0xFF9CA3AF),
                  width: isSelected ? 4 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.green.shade600 : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF111827) : const Color(0xFF4B5563),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
