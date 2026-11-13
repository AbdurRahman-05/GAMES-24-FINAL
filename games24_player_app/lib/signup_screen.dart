import 'api_config.dart';
import 'dart:async';
import 'package:pinput/pinput.dart';
import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _selectedSportIndex = 0; // 0: Football, 1: Cricket, 2: Badminton
  bool _agreeToTerms = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedCountryCode = '+91';

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      body: SafeArea(
        child: SingleChildScrollView(
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
                hintText: 'e.g. Rahul Sharma',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
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
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF9CA3AF),
                          ),
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
                          items: _countryCodes.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
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
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                            ),
                            suffixIcon: TextButton(
                              onPressed: _isOtpVerified
                                  ? null
                                  : _sendOtpAndShowDialog,
                              child: Text(
                                _isOtpVerified ? 'Verified' : 'Verify',
                                style: TextStyle(
                                  color: _isOtpVerified
                                      ? Colors.green
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                controller: _passwordController,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
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
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
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
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_nameController.text.trim().isEmpty) {
                            ToastUtils.showError(context, 'Please enter your full name');
                            return;
                          }
                          if (_mobileController.text.trim().isEmpty) {
                            ToastUtils.showError(context, 'Please enter your mobile number');
                            return;
                          }
                          if (!_isOtpVerified) {
                            ToastUtils.showError(
                              context,
                              'Please verify your mobile number with OTP first',
                            );
                            return;
                          }
                          if (_passwordController.text.trim().isEmpty) {
                            ToastUtils.showError(context, 'Please create a password');
                            return;
                          }
                          if (!_agreeToTerms) {
                            ToastUtils.showError(
                              context,
                              'Please agree to the Terms of Service and Privacy Policy',
                            );
                            return;
                          }
                          _register();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_agreeToTerms && _isOtpVerified)
                        ? Colors.green.shade600
                        : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
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
    ),
  );
}

  Future<void> _sendOtpAndShowDialog() async {
    final mobile = '$_selectedCountryCode${_mobileController.text.trim()}';

    if (_mobileController.text.trim().isEmpty) {
      ToastUtils.showError(context, 'Please enter mobile number');
      return;
    }

    try {
      // First check if mobile already exists
      final checkResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/check-mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobile}),
      );

      if (!mounted) return;
      if (checkResponse.statusCode == 200 || checkResponse.statusCode == 201) {
        final checkData = jsonDecode(checkResponse.body);
        if (checkData['exists'] == true) {
          ToastUtils.showError(
            context,
            'Number already registered. Please use a different number or login.',
          );
          return;
        }
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobile}),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ToastUtils.showSuccess(context, 'Test OTP: ${data["otp"]}');
        _showOtpDialog(mobile);
      } else {
        ToastUtils.showError(context, 'Failed to send OTP');
      }
    } catch (e) {
      ToastUtils.showError(context, 'Error: $e');
    }
  }

  void _showOtpDialog(String mobile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ModernOtpDialog(
          mobile: mobile,
          onVerifySuccess: () {
            setState(() {
              _isOtpVerified = true;
            });
          },
        );
      },
    );
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final mobile = '$_selectedCountryCode${_mobileController.text.trim()}';
    final password = _passwordController.text.trim();

    if (name.isEmpty || mobile.isEmpty || password.isEmpty) {
      ToastUtils.showError(context, 'Please fill all fields');
      return;
    }

    if (!_agreeToTerms) {
      ToastUtils.showError(context, 'Please accept Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': name,
          'mobileNumber': mobile,
          'password': password,
          'preferredSport': [
            'Football',
            'Cricket',
            'Badminton',
          ][_selectedSportIndex],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('fullName', data['fullName'] ?? name);
        await prefs.setString('mobileNumber', data['mobileNumber'] ?? mobile);
        await prefs.setString(
          'preferredSport',
          data['preferredSport'] ??
              ['Football', 'Cricket', 'Badminton'][_selectedSportIndex],
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        try {
          final data = jsonDecode(response.body);
          ToastUtils.showError(
            context,
            data['message'] ?? 'Registration Failed',
          );
        } catch (e) {
          ToastUtils.showError(context, 'Registration Failed');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF9CA3AF),
            size: 22,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.greenAccent.shade400,
              width: 2,
            ),
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
          color: isSelected
              ? const Color(0xFFF0FDF4)
              : Colors.white,
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
              color: isSelected
                  ? Colors.green.shade600
                  : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.green.shade600
                    : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernOtpDialog extends StatefulWidget {
  final String mobile;
  final VoidCallback onVerifySuccess;

  const ModernOtpDialog({
    super.key,
    required this.mobile,
    required this.onVerifySuccess,
  });

  @override
  State<ModernOtpDialog> createState() => _ModernOtpDialogState();
}

class _ModernOtpDialogState extends State<ModernOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  int _timerSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;
  String _status = 'neutral'; // 'neutral', 'error', 'success'

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timerSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          setState(() {
            _timerSeconds--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) return;

    setState(() {
      _isLoading = true;
      _status = 'neutral';
    });

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': widget.mobile, 'otp': otp}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _status = 'success';
          _isLoading = false;
        });
        widget.onVerifySuccess();
        // Wait a bit to show the success state then pop
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() {
          _status = 'error';
          _isLoading = false;
        });
        _otpController.clear();
      }
    } catch (e) {
      setState(() {
        _status = 'error';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _status = 'neutral';
    });
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': widget.mobile}),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        ToastUtils.showSuccess(context, 'Test OTP: ${data["otp"]}');
      }
      _startTimer();
    } catch (e) {
      // Handle error quietly
    }
  }

  Widget _buildFace() {
    if (_status == 'success') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFDE68A),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.sentiment_very_satisfied,
                size: 50,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verified!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome!',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFDE68A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _status == 'error'
                  ? Icons.sentiment_dissatisfied
                  : Icons.sentiment_satisfied,
              size: 50,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'OTP Verification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the 4-digit code',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _status == 'error' ? Colors.red : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
        ),
        child: _status == 'success'
            ? _buildFace()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFace(),
                  const SizedBox(height: 32),
                  Pinput(
                    length: 4,
                    controller: _otpController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                          color: const Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                    ),
                    onCompleted: (pin) => _verify(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF8B5CF6,
                        ), // Purple color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '00:${_timerSeconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _timerSeconds == 0 ? _resendOtp : null,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: _timerSeconds == 0
                            ? const Color(0xFF8B5CF6)
                            : Colors.black38,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
