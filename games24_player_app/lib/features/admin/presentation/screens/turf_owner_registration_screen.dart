import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';

class TurfOwnerRegistrationScreen extends StatefulWidget {
  const TurfOwnerRegistrationScreen({super.key});

  @override
  State<TurfOwnerRegistrationScreen> createState() =>
      _TurfOwnerRegistrationScreenState();
}

class _TurfOwnerRegistrationScreenState
    extends State<TurfOwnerRegistrationScreen> {
  int _currentStep = 0;

  // Step 1 Controllers
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedArea = 'KK Nagar';

  // Step 2 OTP State
  final TextEditingController _mobileOtpController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();
  bool _isMobileVerified = false;
  bool _isEmailVerified = false;

  // Step 3 Facilities State

  bool _hasWater = false;
  bool _hasParking = false;
  bool _hasToilet = false;
  bool _hasFloodlights = false;
  bool _hasChangingRoom = false;
  bool _hasFirstAid = false;
  int _photosUploadedCount = 0;

  // Step 4 KYC & Bank Controllers
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  bool _isAadhaarUploaded = false;
  bool _isPanUploaded = false;
  bool _isGstUploaded = false;

  void _toggleAadhaarUpload() => setState(() => _isAadhaarUploaded = !_isAadhaarUploaded);
  void _togglePanUpload() => setState(() => _isPanUploaded = !_isPanUploaded);
  void _toggleGstUpload() => setState(() => _isGstUploaded = !_isGstUploaded);
  void _addPhoto() => setState(() => _photosUploadedCount = (_photosUploadedCount + 1).clamp(0, 4));

  @override
  void dispose() {
    _venueNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _mobileOtpController.dispose();
    _emailOtpController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1 && (!_isMobileVerified || !_isEmailVerified)) {
      ToastUtils.showError(context, "Please verify both Mobile and Email OTP before proceeding.");
      return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Owner Registration & KYC'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Header Progress Indicator
            _buildStepperProgressHeader(theme),

            // Active Step View Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildActiveStepView(theme),
              ),
            ),

            // Bottom Navigation Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperProgressHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepDot(0, 'Identity'),
          _buildStepConnector(0),
          _buildStepDot(1, 'OTP'),
          _buildStepConnector(1),
          _buildStepDot(2, 'Pricing'),
          _buildStepConnector(2),
          _buildStepDot(3, 'KYC'),
          _buildStepConnector(3),
          _buildStepDot(4, 'Approval'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int index, String label) {
    final isActive = _currentStep >= index;
    final isCurrent = _currentStep == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: isActive ? AppColors.primary : Colors.grey[300],
          child: isCurrent
              ? const Icon(Icons.edit, size: 11, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey[700],
                  ),
                ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int index) {
    final isActive = _currentStep > index;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: isActive ? AppColors.primary : Colors.grey[300],
      ),
    );
  }

  Widget _buildActiveStepView(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1VenueProfile(theme);
      case 1:
        return _buildStep2DualOtpVerification(theme);
      case 2:
        return _buildStep3PricingAndFacilities(theme);
      case 3:
        return _buildStep4KycAndDocuments(theme);
      case 4:
        return _buildStep5SubmittedForApproval(theme);
      default:
        return _buildStep1VenueProfile(theme);
    }
  }

  // STEP 1: Venue & Owner Identity Profile
  Widget _buildStep1VenueProfile(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Venue & Owner Identity',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Enter your sports venue name and owner contact profile details.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),

        AppTextField(
          label: 'Sports Venue / Turf Name',
          hint: 'e.g. Madurai Champions Turf',
          controller: _venueNameController,
          prefixIcon: Icons.stadium_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner Full Name',
          hint: 'e.g. Karthikeyan M',
          controller: _ownerNameController,
          prefixIcon: Icons.person_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner Phone Number',
          hint: 'Enter 10-digit mobile number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner Email Address',
          hint: 'e.g. contact@yourturf.in',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Full Street Address',
          hint: 'Enter complete street address',
          controller: _addressController,
          prefixIcon: Icons.place_rounded,
        ),
        const SizedBox(height: 14),

        Text('Madurai Neighborhood Area', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedArea,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          items: SportsData.maduraiAreas.map((area) {
            return DropdownMenuItem(value: area, child: Text(area));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedArea = val);
          },
        ),
      ],
    );
  }

  // STEP 2: Dual OTP Verification (Mobile & Email)
  Widget _buildStep2DualOtpVerification(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Mobile & Email OTP Verification',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Verify your contact phone number and email address to activate your account.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),

        // Mobile OTP Box
        AppCard(
          color: _isMobileVerified ? AppColors.success.withValues(alpha: 0.08) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mobile: +91 ${_phoneController.text}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isMobileVerified) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Verified ✅',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (!_isMobileVerified) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Mobile OTP Code',
                        hint: 'Enter 4-digit OTP',
                        controller: _mobileOtpController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: AppButton(
                        text: 'Verify SMS',
                        height: 48,
                        onPressed: () {
                          setState(() => _isMobileVerified = true);
                          ToastUtils.showSuccess(context, "Mobile Phone Number Verified ✅");
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Email OTP Box
        AppCard(
          color: _isEmailVerified ? AppColors.success.withValues(alpha: 0.08) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.email_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Email: ${_emailController.text}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEmailVerified) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Verified ✅',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (!_isEmailVerified) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Email OTP Code',
                        hint: 'Enter 4-digit OTP',
                        controller: _emailOtpController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: AppButton(
                        text: 'Verify Email',
                        height: 48,
                        onPressed: () {
                          setState(() => _isEmailVerified = true);
                          ToastUtils.showSuccess(context, "Email Address Verified ✅");
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: Photos & Facilities (Pricing configured per sport in Profile Page)
  Widget _buildStep3PricingAndFacilities(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Venue Photos & Amenities',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Upload venue photos and select amenities for your sports turf.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),

        // Info Banner: Pricing configured in Profile Page
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing Configured per Sport in Profile 🏟️',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hourly rates (weekday, weekend, day, and night slots) are configured based on individual sports inside your Turf Owner Profile Page after login.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Photos Uploader
        Text('Upload Venue Photos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            final isUploaded = i < _photosUploadedCount;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: _addPhoto,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: isUploaded ? AppColors.primary.withValues(alpha: 0.12) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isUploaded ? AppColors.primary : Colors.grey[400]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isUploaded ? Icons.photo_library_rounded : Icons.add_a_photo_rounded,
                            color: isUploaded ? AppColors.primary : Colors.grey[600], size: 22),
                        const SizedBox(height: 4),
                        Text(isUploaded ? 'Photo ${i + 1}' : '+ Add Photo',
                            style: TextStyle(fontSize: 9, color: isUploaded ? AppColors.primary : Colors.grey[600], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Amenities Checklist
        Text('Venue Facilities & Amenities', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('🚰 Purified Drinking Water Facility'),
          value: _hasWater,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasWater = val ?? true),
        ),
        CheckboxListTile(
          title: const Text('🅿️ Dedicated Parking (Two-Wheeler & Four-Wheeler)'),
          value: _hasParking,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasParking = val ?? true),
        ),
        CheckboxListTile(
          title: const Text('🚻 Restroom & Toilet Facilities'),
          value: _hasToilet,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasToilet = val ?? true),
        ),
        CheckboxListTile(
          title: const Text('💡 LED Night Floodlights'),
          value: _hasFloodlights,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasFloodlights = val ?? true),
        ),
        CheckboxListTile(
          title: const Text('🚿 Changing Rooms & Shower Units'),
          value: _hasChangingRoom,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasChangingRoom = val ?? true),
        ),
        CheckboxListTile(
          title: const Text('🏥 First Aid Kit & Safety Gear'),
          value: _hasFirstAid,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasFirstAid = val ?? true),
        ),
      ],
    );
  }

  // STEP 4: Business KYC Documents & Bank Payout
  Widget _buildStep4KycAndDocuments(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Business KYC & Bank Details',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Provide GST, PAN, Aadhaar numbers and bank details for automated weekly payouts.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),

        AppTextField(
          label: 'GSTIN Business Number',
          hint: 'Enter 15-digit GSTIN (optional)',
          controller: _gstinController,
          prefixIcon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner PAN Card Number',
          hint: 'Enter 10-digit PAN',
          controller: _panController,
          prefixIcon: Icons.badge_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner Aadhaar Card Number',
          hint: 'Enter 12-digit Aadhaar Number',
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 20),

        Text('Attach KYC Documents', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: AppCard(
                onTap: _toggleAadhaarUpload,
                color: _isAadhaarUploaded ? AppColors.success.withValues(alpha: 0.1) : null,
                child: Column(
                  children: [
                    Icon(_isAadhaarUploaded ? Icons.task_alt_rounded : Icons.upload_file_rounded,
                        color: _isAadhaarUploaded ? AppColors.success : AppColors.primary, size: 24),
                    const SizedBox(height: 4),
                    Text(_isAadhaarUploaded ? 'Aadhaar Attached' : 'Attach Aadhaar',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isAadhaarUploaded ? AppColors.success : AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppCard(
                onTap: _togglePanUpload,
                color: _isPanUploaded ? AppColors.success.withValues(alpha: 0.1) : null,
                child: Column(
                  children: [
                    Icon(_isPanUploaded ? Icons.task_alt_rounded : Icons.upload_file_rounded,
                        color: _isPanUploaded ? AppColors.success : AppColors.primary, size: 24),
                    const SizedBox(height: 4),
                    Text(_isPanUploaded ? 'PAN Attached' : 'Attach PAN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isPanUploaded ? AppColors.success : AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppCard(
                onTap: _toggleGstUpload,
                color: _isGstUploaded ? AppColors.success.withValues(alpha: 0.1) : null,
                child: Column(
                  children: [
                    Icon(_isGstUploaded ? Icons.task_alt_rounded : Icons.upload_file_rounded,
                        color: _isGstUploaded ? AppColors.success : AppColors.primary, size: 24),
                    const SizedBox(height: 4),
                    Text(_isGstUploaded ? 'GST Cert Attached' : 'Attach GST',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isGstUploaded ? AppColors.success : AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text('Payout Bank Account & UPI', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        AppTextField(
          label: 'Bank Account Number',
          hint: 'Enter Bank Account Number',
          controller: _bankAccountController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Bank IFSC Code',
          hint: 'Enter Bank IFSC Code (e.g. HDFC0001234)',
          controller: _ifscController,
          prefixIcon: Icons.code_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Partner UPI ID',
          hint: 'e.g. username@upi',
          controller: _upiIdController,
          prefixIcon: Icons.payment_rounded,
        ),
      ],
    );
  }

  // STEP 5: Sent to Super Admin for Verification & Approval
  Widget _buildStep5SubmittedForApproval(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.warning,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 54),
        ),
        const SizedBox(height: 24),
        Text(
          'Sent to Super Admin for Verification ⏳',
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your venue details and KYC documents for ${_venueNameController.text} have been securely sent to the PlayHub Super Admin.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        AppCard(
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Application Tracking Code:'),
                  Text('REG-MAD-8821', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Venue Name:'),
                  Text(_venueNameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Owner Name:'),
                  Text(_ownerNameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('OTP Mobile & Email:'),
                  const Text('VERIFIED ✅', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Super Admin Audit Status:'),
                  const Text('PENDING APPROVAL',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        AppButton(
          text: 'Launch Admin Partner Hub Preview',
          icon: Icons.dashboard_rounded,
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    if (_currentStep == 4) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                text: 'Back',
                type: AppButtonType.outline,
                onPressed: _prevStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              text: _currentStep == 3 ? 'Send to Super Admin for Verification' : 'Continue to Next Step',
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }
}
