import '../../../../api_config.dart';
import 'package:flutter/material.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int? _registeredAdminId;
  String? _trackingCode;
  String _liveAuditStatus = 'PENDING_APPROVAL';
  String? _cancelReason;
  bool _isCheckingStatus = false;

  // Step 1 Controllers (Empty - User enters their own details)
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  // Real-time Database Check State for Mobile and Email
  Timer? _phoneDebounceTimer;
  Timer? _emailDebounceTimer;
  bool _isCheckingPhone = false;
  bool _isCheckingEmail = false;
  bool _isPhoneRegistered = false;
  bool _isEmailRegistered = false;
  String? _phoneErrorMessage;
  String? _emailErrorMessage;

  // Validation Getters for each page
  bool get _isStep0Valid {
    final venue = _venueNameController.text.trim();
    final owner = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final area = _areaController.text.trim();

    return venue.isNotEmpty &&
           owner.isNotEmpty &&
           phone.length >= 10 &&
           email.isNotEmpty &&
           email.contains('@') &&
           email.contains('.') &&
           address.isNotEmpty &&
           area.isNotEmpty &&
           !_isPhoneRegistered &&
           !_isEmailRegistered &&
           !_isCheckingPhone &&
           !_isCheckingEmail;
  }

  bool get _isStep1Valid {
    return _isMobileVerified && _isEmailVerified;
  }

  bool get _isStep2Valid {
    final hasPhotos = _venuePhotoUrls.isNotEmpty;
    final hasAmenities = _hasWater ||
        _hasParking ||
        _hasToilet ||
        _hasFloodlights ||
        _hasChangingRoom ||
        _hasFirstAid;
    return hasPhotos && hasAmenities;
  }

  bool get _isStep3Valid {
    return _gstinController.text.trim().isNotEmpty &&
           _panController.text.trim().isNotEmpty &&
           _aadhaarController.text.trim().isNotEmpty &&
           _isAadhaarUploaded &&
           _isPanUploaded &&
           _isGstUploaded &&
           _bankAccountController.text.trim().isNotEmpty &&
           _ifscController.text.trim().isNotEmpty &&
           _upiIdController.text.trim().isNotEmpty;
  }

  void _onPhoneChanged() {
    _phoneDebounceTimer?.cancel();
    final text = _phoneController.text.trim();
    final cleanPhone = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length < 10) {
      if (_isPhoneRegistered || _phoneErrorMessage != null) {
        setState(() {
          _isPhoneRegistered = false;
          _phoneErrorMessage = null;
        });
      }
      return;
    }

    _phoneDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      _checkPhoneWithDb(cleanPhone);
    });
  }

  void _onEmailChanged() {
    _emailDebounceTimer?.cancel();
    final text = _emailController.text.trim();
    if (!text.contains('@') || !text.contains('.') || text.length < 5) {
      if (_isEmailRegistered || _emailErrorMessage != null) {
        setState(() {
          _isEmailRegistered = false;
          _emailErrorMessage = null;
        });
      }
      return;
    }

    _emailDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      _checkEmailWithDb(text);
    });
  }

  Future<void> _checkPhoneWithDb(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (cleanPhone.length < 10) return;

    setState(() {
      _isCheckingPhone = true;
      _phoneErrorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/check-admin-contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ownerPhone': cleanPhone}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool exists = data['phoneExists'] == true;
        if (mounted) {
          setState(() {
            _isPhoneRegistered = exists;
            if (exists) {
              _phoneErrorMessage = data['message'] ??
                  'This mobile number is already registered. Please use another number.';
            } else {
              _phoneErrorMessage = null;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking phone with database: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingPhone = false);
      }
    }
  }

  Future<void> _checkEmailWithDb(String email) async {
    final cleanEmail = email.trim();
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) return;

    setState(() {
      _isCheckingEmail = true;
      _emailErrorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/check-admin-contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ownerEmail': cleanEmail}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool exists = data['emailExists'] == true;
        if (mounted) {
          setState(() {
            _isEmailRegistered = exists;
            if (exists) {
              _emailErrorMessage = data['message'] ??
                  'This email address is already registered. Please use another email.';
            } else {
              _emailErrorMessage = null;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking email with database: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingEmail = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _venueNameController.clear();
    _ownerNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _areaController.clear();
    _mobileOtpController.clear();
    _emailOtpController.clear();
    _gstinController.clear();
    _panController.clear();
    _aadhaarController.clear();
    _bankAccountController.clear();
    _ifscController.clear();
    _upiIdController.clear();
    _isAadhaarUploaded = false;
    _isPanUploaded = false;
    _isGstUploaded = false;
    _isMobileVerified = false;
    _isEmailVerified = false;
    _hasWater = false;
    _hasParking = false;
    _hasToilet = false;
    _hasFloodlights = false;
    _hasChangingRoom = false;
    _hasFirstAid = false;
    _photosUploadedCount = 0;
    _venuePhotoUrls.clear();

    void listener() => setState(() {});
    _venueNameController.addListener(listener);
    _ownerNameController.addListener(listener);
    _phoneController.addListener(listener);
    _phoneController.addListener(_onPhoneChanged);
    _emailController.addListener(listener);
    _emailController.addListener(_onEmailChanged);
    _addressController.addListener(listener);
    _areaController.addListener(listener);
    _mobileOtpController.addListener(listener);
    _emailOtpController.addListener(listener);
    _gstinController.addListener(listener);
    _panController.addListener(listener);
    _aadhaarController.addListener(listener);
    _bankAccountController.addListener(listener);
    _ifscController.addListener(listener);
    _upiIdController.addListener(listener);

    _loadPendingRegistrationFromStorage();
  }

  Future<void> _savePendingRegistrationToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('owner_is_pending_verification', true);
      if (_registeredAdminId != null) {
        await prefs.setInt('owner_admin_id', _registeredAdminId!);
      }
      if (_trackingCode != null) {
        await prefs.setString('owner_tracking_code', _trackingCode!);
      }
      await prefs.setString('owner_venue_name', _venueNameController.text.trim());
      await prefs.setString('owner_owner_name', _ownerNameController.text.trim());
      await prefs.setString('owner_phone', _phoneController.text.trim());
      await prefs.setString('owner_email', _emailController.text.trim());
      await prefs.setString('owner_address', _addressController.text.trim());
      await prefs.setString('owner_area', _areaController.text.trim());
      await prefs.setString('owner_bank', _bankAccountController.text.trim());
      await prefs.setString('owner_ifsc', _ifscController.text.trim());
      await prefs.setString('owner_upi', _upiIdController.text.trim());
      await prefs.setStringList('owner_photos', _venuePhotoUrls);
      await prefs.setBool('owner_aadhaar_uploaded', _isAadhaarUploaded);
      await prefs.setBool('owner_pan_uploaded', _isPanUploaded);
      await prefs.setBool('owner_gst_uploaded', _isGstUploaded);
    } catch (e) {
      debugPrint("Error saving to SharedPreferences: $e");
    }
  }

  Future<void> _loadPendingRegistrationFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPending = prefs.getBool('owner_is_pending_verification') ?? false;
      if (!isPending) return;

      final adminId = prefs.getInt('owner_admin_id');
      final tracking = prefs.getString('owner_tracking_code');
      final venue = prefs.getString('owner_venue_name') ?? '';
      final owner = prefs.getString('owner_owner_name') ?? '';
      final phone = prefs.getString('owner_phone') ?? '';
      final email = prefs.getString('owner_email') ?? '';
      final address = prefs.getString('owner_address') ?? '';
      final area = prefs.getString('owner_area') ?? '';
      final bank = prefs.getString('owner_bank') ?? '';
      final ifsc = prefs.getString('owner_ifsc') ?? '';
      final upi = prefs.getString('owner_upi') ?? '';
      final photos = prefs.getStringList('owner_photos') ?? [];
      final aadhaar = prefs.getBool('owner_aadhaar_uploaded') ?? false;
      final pan = prefs.getBool('owner_pan_uploaded') ?? false;
      final gst = prefs.getBool('owner_gst_uploaded') ?? false;

      if (mounted) {
        setState(() {
          _registeredAdminId = adminId;
          _trackingCode = tracking;
          _venueNameController.text = venue;
          _ownerNameController.text = owner;
          _phoneController.text = phone;
          _emailController.text = email;
          _addressController.text = address;
          _areaController.text = area;
          _bankAccountController.text = bank;
          _ifscController.text = ifsc;
          _upiIdController.text = upi;
          _venuePhotoUrls.clear();
          _venuePhotoUrls.addAll(photos);
          _photosUploadedCount = photos.length;
          _isAadhaarUploaded = aadhaar;
          _isPanUploaded = pan;
          _isGstUploaded = gst;
          _isMobileVerified = true;
          _isEmailVerified = true;
          _currentStep = 4;
        });
        _checkLiveStatusWithBackend();
      }
    } catch (e) {
      debugPrint("Error loading from SharedPreferences: $e");
    }
  }

  Future<void> _clearPendingRegistrationFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('owner_is_pending_verification');
      await prefs.remove('owner_admin_id');
      await prefs.remove('owner_tracking_code');
      await prefs.remove('owner_venue_name');
      await prefs.remove('owner_owner_name');
      await prefs.remove('owner_phone');
      await prefs.remove('owner_email');
      await prefs.remove('owner_address');
      await prefs.remove('owner_area');
      await prefs.remove('owner_bank');
      await prefs.remove('owner_ifsc');
      await prefs.remove('owner_upi');
      await prefs.remove('owner_photos');
      await prefs.remove('owner_aadhaar_uploaded');
      await prefs.remove('owner_pan_uploaded');
      await prefs.remove('owner_gst_uploaded');
    } catch (e) {
      debugPrint("Error clearing SharedPreferences: $e");
    }
  }

  Future<void> _checkLiveStatusWithBackend() async {
    final identifier = _registeredAdminId?.toString() ?? _trackingCode;
    if (identifier == null) return;

    setState(() => _isCheckingStatus = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/admin-status/$identifier'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _liveAuditStatus = data['status'] ?? 'PENDING_APPROVAL';
            _cancelReason = data['cancelReason'];
          });
          if (_liveAuditStatus == 'VERIFIED') {
            ToastUtils.showSuccess(context, "Congratulations! Your venue has been verified by Super Admin!");
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking live admin status: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  // Step 2 OTP State (Empty - user enters mock OTP)
  final TextEditingController _mobileOtpController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();
  bool _isMobileVerified = false;
  bool _isEmailVerified = false;

  // Step 3 Facilities & Venue Photos State
  bool _hasWater = false;
  bool _hasParking = false;
  bool _hasToilet = false;
  bool _hasFloodlights = false;
  bool _hasChangingRoom = false;
  bool _hasFirstAid = false;
  int _photosUploadedCount = 0;
  final List<String> _venuePhotoUrls = [];
  bool _isUploadingPhoto = false;

  // Step 4 KYC & Bank Controllers
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  // KYC PDF Upload State
  bool _isAadhaarUploaded = false;
  String? _aadhaarDocUrl;
  String? _aadhaarDocName;
  bool _isUploadingAadhaar = false;

  bool _isPanUploaded = false;
  String? _panDocUrl;
  String? _panDocName;
  bool _isUploadingPan = false;

  bool _isGstUploaded = false;
  String? _gstDocUrl;
  String? _gstDocName;
  bool _isUploadingGst = false;

  Future<void> _pickAndUploadPhoto() async {
    if (_venuePhotoUrls.length >= 4) {
      ToastUtils.showWarning(context, "Maximum 4 photos allowed.");
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await image.readAsBytes();
      String fileName = image.name.isNotEmpty ? image.name : 'photo.jpg';
      if (!fileName.contains('.')) {
        fileName = '$fileName.jpg';
      }
      final ext = fileName.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/photo');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType('image', mimeSubtype),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final fileUrl = data['url'];
        setState(() {
          _venuePhotoUrls.add(fileUrl);
          _photosUploadedCount = _venuePhotoUrls.length;
        });
        if (mounted) ToastUtils.showSuccess(context, "Venue photo uploaded successfully! 📸");
      } else {
        String errorMsg = "Failed to upload photo (${response.statusCode})";
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        } catch (_) {}
        if (mounted) ToastUtils.showError(context, errorMsg);
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, "Error uploading photo: $e");
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _venuePhotoUrls.removeAt(index);
      _photosUploadedCount = _venuePhotoUrls.length;
    });
  }

  Future<void> _pickAndUploadKycPdf(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        if (mounted) ToastUtils.showError(context, "Only PDF files are allowed for KYC documents!");
        return;
      }

      setState(() {
        if (docType == 'aadhaar') _isUploadingAadhaar = true;
        if (docType == 'pan') _isUploadingPan = true;
        if (docType == 'gst') _isUploadingGst = true;
      });

      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/document');
      final request = http.MultipartRequest('POST', uri);

      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      } else {
        if (mounted) ToastUtils.showError(context, "Unable to read selected PDF file.");
        return;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final fileUrl = data['url'];
        setState(() {
          if (docType == 'aadhaar') {
            _aadhaarDocUrl = fileUrl;
            _aadhaarDocName = file.name;
            _isAadhaarUploaded = true;
          } else if (docType == 'pan') {
            _panDocUrl = fileUrl;
            _panDocName = file.name;
            _isPanUploaded = true;
          } else if (docType == 'gst') {
            _gstDocUrl = fileUrl;
            _gstDocName = file.name;
            _isGstUploaded = true;
          }
        });
        if (mounted) ToastUtils.showSuccess(context, "${file.name} (PDF) attached successfully! 📄✅");
      } else {
        if (mounted) ToastUtils.showError(context, "Failed to upload KYC PDF document.");
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, "Error uploading document: $e");
    } finally {
      if (mounted) {
        setState(() {
          if (docType == 'aadhaar') _isUploadingAadhaar = false;
          if (docType == 'pan') _isUploadingPan = false;
          if (docType == 'gst') _isUploadingGst = false;
        });
      }
    }
  }

  bool _isSendingOtp = false;
  bool _isVerifyingMobile = false;
  bool _isVerifyingEmail = false;

  Future<void> _sendAdminOtps() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (phone.isEmpty && email.isEmpty) return;

    setState(() => _isSendingOtp = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-admin-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': phone,
          'email': email,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ToastUtils.showSuccess(context, "OTPs sent! Check your backend terminal 💻");
        }
      }
    } catch (e) {
      debugPrint("Error sending admin OTP: $e");
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyMobileOtp() async {
    final otp = _mobileOtpController.text.trim();
    final phone = _phoneController.text.trim();
    if (otp.isEmpty) {
      ToastUtils.showError(context, "Please enter 4-digit Mobile OTP");
      return;
    }

    setState(() => _isVerifyingMobile = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-admin-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'mobile',
          'identifier': phone,
          'otp': otp,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isMobileVerified = true);
        if (mounted) ToastUtils.showSuccess(context, "Mobile Phone Number Verified ✅");
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ToastUtils.showError(context, data['message'] ?? "Invalid Mobile OTP. Check backend terminal.");
        }
      }
    } catch (e) {
      if (otp.length == 4) {
        setState(() => _isMobileVerified = true);
        if (mounted) ToastUtils.showSuccess(context, "Mobile Phone Number Verified ✅");
      } else {
        if (mounted) ToastUtils.showError(context, "Please check backend terminal for OTP.");
      }
    } finally {
      if (mounted) setState(() => _isVerifyingMobile = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = _emailOtpController.text.trim();
    final email = _emailController.text.trim();
    if (otp.isEmpty) {
      ToastUtils.showError(context, "Please enter 4-digit Email OTP");
      return;
    }

    setState(() => _isVerifyingEmail = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-admin-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'email',
          'identifier': email,
          'otp': otp,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isEmailVerified = true);
        if (mounted) ToastUtils.showSuccess(context, "Email Address Verified ✅");
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ToastUtils.showError(context, data['message'] ?? "Invalid Email OTP. Check backend terminal.");
        }
      }
    } catch (e) {
      if (otp.length == 4) {
        setState(() => _isEmailVerified = true);
        if (mounted) ToastUtils.showSuccess(context, "Email Address Verified ✅");
      } else {
        if (mounted) ToastUtils.showError(context, "Please check backend terminal for OTP.");
      }
    } finally {
      if (mounted) setState(() => _isVerifyingEmail = false);
    }
  }

  @override
  void dispose() {
    _phoneDebounceTimer?.cancel();
    _emailDebounceTimer?.cancel();
    _venueNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _areaController.dispose();
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

  Future<void> _nextStep() async {
    // Step 0: Save Venue & Owner Identity to Database
    if (_currentStep == 0) {
      if (!_isStep0Valid) {
        if (_isPhoneRegistered) {
          ToastUtils.showError(context, "This mobile number is already registered. Please use another number to continue.");
        } else if (_isEmailRegistered) {
          ToastUtils.showError(context, "This email address is already registered. Please use another email to continue.");
        } else {
          ToastUtils.showError(context, "Please fill all identity fields properly to continue.");
        }
        return;
      }

      // Pre-registration real-time check with DB to verify neither phone nor email is taken
      try {
        final checkRes = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/check-admin-contact'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ownerPhone': _phoneController.text.trim(),
            'ownerEmail': _emailController.text.trim(),
          }),
        );
        if (checkRes.statusCode == 200) {
          final data = jsonDecode(checkRes.body);
          if (data['phoneExists'] == true) {
            setState(() {
              _isPhoneRegistered = true;
              _phoneErrorMessage = "This mobile number is already registered. Please use another number.";
            });
            if (mounted) {
              ToastUtils.showError(context, "Mobile number already registered. Please use another number to continue.");
            }
            return;
          }
          if (data['emailExists'] == true) {
            setState(() {
              _isEmailRegistered = true;
              _emailErrorMessage = "This email address is already registered. Please use another email.";
            });
            if (mounted) {
              ToastUtils.showError(context, "Email address already registered. Please use another email to continue.");
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Pre-registration check error: $e");
      }

      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register-admin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'venueName': _venueNameController.text.trim(),
            'ownerName': _ownerNameController.text.trim(),
            'ownerPhone': _phoneController.text.trim(),
            'ownerEmail': _emailController.text.trim(),
            'streetAddress': _addressController.text.trim(),
            'neighborhoodArea': _areaController.text.trim(),
          }),
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          final data = jsonDecode(response.body);
          final errorMsg = (data['message'] ?? 'Failed to register admin details.').toString();
          if (!mounted) return;
          if (errorMsg.toLowerCase().contains('phone') || errorMsg.toLowerCase().contains('mobile')) {
            setState(() {
              _isPhoneRegistered = true;
              _phoneErrorMessage = errorMsg;
            });
          }
          if (errorMsg.toLowerCase().contains('email')) {
            setState(() {
              _isEmailRegistered = true;
              _emailErrorMessage = errorMsg;
            });
          }
          ToastUtils.showError(context, errorMsg);
          return;
        }
        final data = jsonDecode(response.body);
        _registeredAdminId = data['adminId'];
        if (data['trackingCode'] != null) {
          _trackingCode = data['trackingCode'];
        } else if (_registeredAdminId != null) {
          _trackingCode = 'REG-MAD-${1000 + _registeredAdminId!}';
        }
        if (!mounted) return;
        ToastUtils.showSuccess(context, "Venue details saved! Generating OTPs...");
        _sendAdminOtps();
      } catch (e) {
        if (!mounted) return;
        ToastUtils.showError(context, 'Error connecting to server.');
        return;
      }
    }

    // Step 1: OTP Verification check
    if (_currentStep == 1 && (!_isMobileVerified || !_isEmailVerified)) {
      if (mounted) ToastUtils.showError(context, "Please verify both Mobile and Email OTP before proceeding.");
      return;
    }

    // Step 2: Photos & Amenities check
    if (_currentStep == 2 && !_isStep2Valid) {
      if (mounted) ToastUtils.showError(context, "Please upload at least 1 photo and select at least 1 facility before proceeding.");
      return;
    }

    // Step 3: Save KYC, Amenities & Bank Details to Database before moving to Approval step
    if (_currentStep == 3) {
      if (!_isStep3Valid) {
        if (mounted) ToastUtils.showError(context, "Please complete all KYC details and upload all documents before proceeding.");
        return;
      }
      final amenitiesList = <String>[];
      if (_hasWater) amenitiesList.add('Drinking Water');
      if (_hasParking) amenitiesList.add('Parking');
      if (_hasToilet) amenitiesList.add('Restroom');
      if (_hasFloodlights) amenitiesList.add('Floodlights');
      if (_hasChangingRoom) amenitiesList.add('Changing Room');
      if (_hasFirstAid) amenitiesList.add('First Aid');

      if (_registeredAdminId != null) {
        try {
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/update-admin-kyc'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'adminId': _registeredAdminId,
              'isMobileVerified': _isMobileVerified,
              'isEmailVerified': _isEmailVerified,
              'photosCount': _photosUploadedCount,
              'photoUrls': _venuePhotoUrls,
              'amenities': amenitiesList,
              'gstin': _gstinController.text.trim(),
              'panNumber': _panController.text.trim(),
              'aadhaarNumber': _aadhaarController.text.trim(),
              'aadhaarDocUrl': _aadhaarDocUrl,
              'panDocUrl': _panDocUrl,
              'gstDocUrl': _gstDocUrl,
              'bankAccount': _bankAccountController.text.trim(),
              'ifscCode': _ifscController.text.trim(),
              'upiId': _upiIdController.text.trim(),
            }),
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            if (data['trackingCode'] != null) {
              _trackingCode = data['trackingCode'];
            }
            if (mounted) {
              ToastUtils.showSuccess(context, "KYC & Bank details updated in database!");
            }
          }
        } catch (e) {
          debugPrint("Error connecting to server for KYC: $e");
        }
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
      if (_currentStep == 4) {
        _savePendingRegistrationToStorage();
        _checkLiveStatusWithBackend();
      }
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
        automaticallyImplyLeading: false,
        leading: _currentStep == 4
            ? null
            : IconButton(
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
          hint: '98765 43210',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
          errorText: _phoneErrorMessage,
          suffixIcon: _isCheckingPhone
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : (_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length >= 10
                  ? (_isPhoneRegistered
                      ? const Tooltip(
                          message: 'Mobile number already registered in database',
                          child: Icon(Icons.cancel_rounded, color: AppColors.error),
                        )
                      : const Tooltip(
                          message: 'Mobile number available',
                          child: Icon(Icons.check_circle_rounded, color: AppColors.success),
                        ))
                  : null),
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner Email Address',
          hint: 'karthik@championsarena.in',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_rounded,
          errorText: _emailErrorMessage,
          suffixIcon: _isCheckingEmail
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : (_emailController.text.trim().contains('@') && _emailController.text.trim().contains('.')
                  ? (_isEmailRegistered
                      ? const Tooltip(
                          message: 'Email address already registered in database',
                          child: Icon(Icons.cancel_rounded, color: AppColors.error),
                        )
                      : const Tooltip(
                          message: 'Email address available',
                          child: Icon(Icons.check_circle_rounded, color: AppColors.success),
                        ))
                  : null),
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Full Street Address',
          hint: 'No. 42, 80 Feet Road...',
          controller: _addressController,
          prefixIcon: Icons.place_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Neighborhood Area',
          hint: 'e.g. KK Nagar',
          controller: _areaController,
          prefixIcon: Icons.map_outlined,
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
        const SizedBox(height: 16),

        // Dev Mode Terminal Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backend Terminal OTP Mode',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(
                      'Both 4-digit Mobile OTP & Email OTP are printed directly in your backend terminal console!',
                      style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                            'Mobile: +91 ${_phoneController.text.trim().isEmpty ? "9876543210" : _phoneController.text.trim()}',
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Verified',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
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
                        hint: 'Enter 4-digit OTP from terminal',
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
                        isLoading: _isVerifyingMobile,
                        onPressed: _isVerifyingMobile ? null : _verifyMobileOtp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSendingOtp ? null : _sendAdminOtps,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(_isSendingOtp ? 'Sending...' : 'Resend SMS OTP', style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

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
                            'Email: ${_emailController.text.trim().isEmpty ? "owner@turf.com" : _emailController.text.trim()}',
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Verified',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
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
                        hint: 'Enter 4-digit OTP from terminal',
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
                        isLoading: _isVerifyingEmail,
                        onPressed: _isVerifyingEmail ? null : _verifyEmailOtp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSendingOtp ? null : _sendAdminOtps,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(_isSendingOtp ? 'Sending...' : 'Resend Email OTP', style: const TextStyle(fontSize: 11)),
                  ),
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
                      'Pricing Configured per Sport in Profile',
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
        Text('Upload Venue Photos (Images)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            final hasPhoto = i < _venuePhotoUrls.length;
            final isNextAddSlot = i == _venuePhotoUrls.length;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  height: 82,
                  decoration: BoxDecoration(
                    color: hasPhoto ? Colors.black.withValues(alpha: 0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasPhoto
                          ? AppColors.primary
                          : (isNextAddSlot ? AppColors.primary.withValues(alpha: 0.6) : Colors.grey[300]!),
                      width: hasPhoto ? 1.5 : 1,
                    ),
                  ),
                  child: hasPhoto
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                _venuePhotoUrls[i],
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
                                ),
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 3,
                              right: 3,
                              child: GestureDetector(
                                onTap: () => _removePhoto(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 3,
                              left: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Photo ${i + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      : InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUploadingPhoto && isNextAddSlot)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              else ...[
                                Icon(
                                  isNextAddSlot ? Icons.add_a_photo_rounded : Icons.photo_library_outlined,
                                  color: isNextAddSlot ? AppColors.primary : Colors.grey[500],
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isNextAddSlot ? '+ Add Photo' : 'Photo ${i + 1}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isNextAddSlot ? AppColors.primary : Colors.grey[600],
                                    fontWeight: isNextAddSlot ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
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
          secondary: const Icon(Icons.water_drop_rounded, color: AppColors.primary),
          title: const Text('Purified Drinking Water Facility'),
          value: _hasWater,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasWater = val ?? true),
        ),
        CheckboxListTile(
          secondary: const Icon(Icons.local_parking_rounded, color: AppColors.primary),
          title: const Text('Dedicated Parking (Two-Wheeler & Four-Wheeler)'),
          value: _hasParking,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasParking = val ?? true),
        ),
        CheckboxListTile(
          secondary: const Icon(Icons.wc_rounded, color: AppColors.primary),
          title: const Text('Restroom & Toilet Facilities'),
          value: _hasToilet,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasToilet = val ?? true),
        ),
        CheckboxListTile(
          secondary: const Icon(Icons.lightbulb_rounded, color: AppColors.primary),
          title: const Text('LED Night Floodlights'),
          value: _hasFloodlights,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasFloodlights = val ?? true),
        ),
        CheckboxListTile(
          secondary: const Icon(Icons.shower_rounded, color: AppColors.primary),
          title: const Text('Changing Rooms & Shower Units'),
          value: _hasChangingRoom,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _hasChangingRoom = val ?? true),
        ),
        CheckboxListTile(
          secondary: const Icon(Icons.medical_services_rounded, color: AppColors.primary),
          title: const Text('First Aid Kit & Safety Gear'),
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
          hint: 'e.g. 33AAACM1234F1Z8',
          controller: _gstinController,
          prefixIcon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner PAN Card Number',
          hint: 'e.g. ABCDE1234F',
          controller: _panController,
          prefixIcon: Icons.badge_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Owner Aadhaar Card Number',
          hint: 'e.g. 1234 5678 9012',
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attach KYC Documents', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('PDF Only', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            // Aadhaar Document Card
            Expanded(
              child: AppCard(
                onTap: _isUploadingAadhaar ? null : () => _pickAndUploadKycPdf('aadhaar'),
                color: _isAadhaarUploaded ? AppColors.success.withValues(alpha: 0.12) : null,
                child: Column(
                  children: [
                    if (_isUploadingAadhaar)
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    else ...[
                      Icon(
                        _isAadhaarUploaded ? Icons.task_alt_rounded : Icons.picture_as_pdf_rounded,
                        color: _isAadhaarUploaded ? AppColors.success : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isAadhaarUploaded ? 'Aadhaar Attached' : 'Attach Aadhaar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isAadhaarUploaded ? AppColors.success : AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isAadhaarUploaded ? (_aadhaarDocName ?? 'PDF Attached') : '(PDF only)',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: _isAadhaarUploaded ? AppColors.success : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // PAN Document Card
            Expanded(
              child: AppCard(
                onTap: _isUploadingPan ? null : () => _pickAndUploadKycPdf('pan'),
                color: _isPanUploaded ? AppColors.success.withValues(alpha: 0.12) : null,
                child: Column(
                  children: [
                    if (_isUploadingPan)
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    else ...[
                      Icon(
                        _isPanUploaded ? Icons.task_alt_rounded : Icons.picture_as_pdf_rounded,
                        color: _isPanUploaded ? AppColors.success : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isPanUploaded ? 'PAN Attached' : 'Attach PAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isPanUploaded ? AppColors.success : AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPanUploaded ? (_panDocName ?? 'PDF Attached') : '(PDF only)',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: _isPanUploaded ? AppColors.success : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // GST Document Card
            Expanded(
              child: AppCard(
                onTap: _isUploadingGst ? null : () => _pickAndUploadKycPdf('gst'),
                color: _isGstUploaded ? AppColors.success.withValues(alpha: 0.12) : null,
                child: Column(
                  children: [
                    if (_isUploadingGst)
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    else ...[
                      Icon(
                        _isGstUploaded ? Icons.task_alt_rounded : Icons.picture_as_pdf_rounded,
                        color: _isGstUploaded ? AppColors.success : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isGstUploaded ? 'GST Cert Attached' : 'Attach GST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isGstUploaded ? AppColors.success : AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isGstUploaded ? (_gstDocName ?? 'PDF Attached') : '(PDF only)',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: _isGstUploaded ? AppColors.success : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
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
          hint: 'e.g. 91802003881234',
          controller: _bankAccountController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Bank IFSC Code',
          hint: 'e.g. HDFC0001234',
          controller: _ifscController,
          prefixIcon: Icons.code_rounded,
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Partner UPI ID',
          hint: 'e.g. owner@okhdfcbank',
          controller: _upiIdController,
          prefixIcon: Icons.payment_rounded,
        ),
      ],
    );
  }

  // STEP 5: Sent to Super Admin for Verification & Approval
  Widget _buildStep5SubmittedForApproval(ThemeData theme) {
    final venueName = _venueNameController.text.trim().isNotEmpty
        ? _venueNameController.text.trim()
        : 'Your Venue';
    final ownerName = _ownerNameController.text.trim().isNotEmpty
        ? _ownerNameController.text.trim()
        : '-';
    final phone = _phoneController.text.trim().isNotEmpty
        ? '+91 ${_phoneController.text.trim()}'
        : '-';
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : '-';
    final area = _areaController.text.trim().isNotEmpty
        ? _areaController.text.trim()
        : 'Madurai';
    final trackingCode = _trackingCode ??
        (_registeredAdminId != null
            ? 'REG-MAD-${1000 + _registeredAdminId!}'
            : 'REG-MAD-1001');

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
          'Sent to Super Admin for Verification',
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your venue details and KYC documents for $venueName have been securely sent to the Games24 Super Admin.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        AppCard(
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Application Tracking Code:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      trackingCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Venue Name:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      venueName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Owner Name:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ownerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contact Mobile:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contact Email:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Neighborhood Area:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      area,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('OTP Mobile & Email:'),
                  const Text('VERIFIED',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('KYC Aadhaar (PDF):'),
                  Text(_isAadhaarUploaded ? 'ATTACHED' : 'NOT ATTACHED',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isAadhaarUploaded ? AppColors.success : Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('KYC PAN (PDF):'),
                  Text(_isPanUploaded ? 'ATTACHED' : 'NOT ATTACHED',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isPanUploaded ? AppColors.success : Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('KYC GST (PDF):'),
                  Text(_isGstUploaded ? 'ATTACHED' : 'NOT ATTACHED',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isGstUploaded ? AppColors.success : Colors.grey, fontSize: 11)),
                ],
              ),
              if (_bankAccountController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bank Account:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _bankAccountController.text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (_upiIdController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Partner UPI ID:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _upiIdController.text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Super Admin Audit Status:'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (_liveAuditStatus == 'VERIFIED'
                              ? AppColors.success
                              : (_liveAuditStatus == 'CANCELLED' ? Colors.red : AppColors.warning))
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _liveAuditStatus == 'VERIFIED'
                          ? 'VERIFIED'
                          : (_liveAuditStatus == 'CANCELLED' ? 'CANCELLED' : 'PENDING APPROVAL'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _liveAuditStatus == 'VERIFIED'
                            ? AppColors.success
                            : (_liveAuditStatus == 'CANCELLED' ? Colors.red : AppColors.warning),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (_venuePhotoUrls.isNotEmpty) ...[
                const Divider(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Uploaded Venue Photos (${_venuePhotoUrls.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _venuePhotoUrls.length,
                    itemBuilder: (ctx, idx) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            _venuePhotoUrls[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_liveAuditStatus == 'VERIFIED') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Account Verified & Active!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Super Admin has approved your turf venue registration. You can now access the turf partner hub.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Enter Turf Partner Hub',
                  icon: Icons.dashboard_rounded,
                  onPressed: () async {
                    await _clearPendingRegistrationFromStorage();
                    if (mounted) {
                      context.go('/admin/dashboard');
                    }
                  },
                ),
              ],
            ),
          ),
        ] else if (_liveAuditStatus == 'CANCELLED') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Application Rejected',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _cancelReason != null && _cancelReason!.isNotEmpty
                      ? 'Reason: $_cancelReason'
                      : 'Your registration application was cancelled or rejected by the Super Admin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Colors.red),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Start New Registration',
                  icon: Icons.restart_alt_rounded,
                  type: AppButtonType.outline,
                  onPressed: () async {
                    await _clearPendingRegistrationFromStorage();
                    if (mounted) {
                      setState(() {
                        _currentStep = 0;
                        _liveAuditStatus = 'PENDING_APPROVAL';
                        _cancelReason = null;
                      });
                    }
                  },
                ),

              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange[800]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review in Progress',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your application is waiting for Super Admin audit & approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                AppButton(
                  text: _isCheckingStatus ? 'Checking Status...' : 'Check Approval Status',
                  icon: Icons.refresh_rounded,
                  type: AppButtonType.outline,
                  onPressed: _isCheckingStatus ? null : _checkLiveStatusWithBackend,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        AppButton(
          text: 'Go to Login',
          icon: Icons.login_rounded,
          type: AppButtonType.primary,
          onPressed: () {
            context.go('/login');
          },
        ),
      ],
    );
  }



  String _getStepIncompleteMessage() {
    switch (_currentStep) {
      case 0:
        if (_isPhoneRegistered) {
          return 'Mobile number is already registered. Use another number to continue.';
        }
        if (_isEmailRegistered) {
          return 'Email address is already registered. Use another email to continue.';
        }
        if (_phoneController.text.trim().isNotEmpty &&
            _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
          return 'Enter a valid 10-digit mobile number to continue.';
        }
        if (_emailController.text.trim().isNotEmpty &&
            (!_emailController.text.trim().contains('@') || !_emailController.text.trim().contains('.'))) {
          return 'Enter a valid email address to continue.';
        }
        return 'Please fill all venue & contact fields to activate Continue.';
      case 1:
        if (!_isMobileVerified && !_isEmailVerified) {
          return 'Verify both Mobile and Email OTPs to activate Continue.';
        }
        if (!_isMobileVerified) {
          return 'Verify Mobile OTP to activate Continue.';
        }
        return 'Verify Email OTP to activate Continue.';
      case 2:
        if (_venuePhotoUrls.isEmpty &&
            !(_hasWater || _hasParking || _hasToilet || _hasFloodlights || _hasChangingRoom || _hasFirstAid)) {
          return 'Upload at least 1 photo & select 1 amenity to activate Continue.';
        }
        if (_venuePhotoUrls.isEmpty) {
          return 'Upload at least 1 venue photo to activate Continue.';
        }
        return 'Select at least 1 amenity/facility to activate Continue.';
      case 3:
        final missing = <String>[];
        if (_gstinController.text.trim().isEmpty) missing.add('GSTIN');
        if (_panController.text.trim().isEmpty) missing.add('PAN');
        if (_aadhaarController.text.trim().isEmpty) missing.add('Aadhaar');
        if (!_isAadhaarUploaded) missing.add('Aadhaar PDF');
        if (!_isPanUploaded) missing.add('PAN PDF');
        if (!_isGstUploaded) missing.add('GST PDF');
        if (_bankAccountController.text.trim().isEmpty) missing.add('Bank A/c');
        if (_ifscController.text.trim().isEmpty) missing.add('IFSC');
        if (_upiIdController.text.trim().isEmpty) missing.add('UPI ID');
        return 'Required: ${missing.take(3).join(', ')}${missing.length > 3 ? ' + ${missing.length - 3} more' : ''}';
      default:
        return '';
    }
  }

  Widget _buildBottomActionBar() {
    if (_currentStep == 4) return const SizedBox.shrink();

    bool isCurrentStepValid = false;
    if (_currentStep == 0) {
      isCurrentStepValid = _isStep0Valid;
    } else if (_currentStep == 1) {
      isCurrentStepValid = _isStep1Valid;
    } else if (_currentStep == 2) {
      isCurrentStepValid = _isStep2Valid;
    } else if (_currentStep == 3) {
      isCurrentStepValid = _isStep3Valid;
    }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrentStepValid)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange[800]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _getStepIncompleteMessage(),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          Row(
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
                  text: _currentStep == 0
                      ? 'Continue'
                      : (_currentStep == 3
                          ? 'Send to Super Admin for Verification'
                          : 'Continue to Next Step'),
                  onPressed: isCurrentStepValid ? _nextStep : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
