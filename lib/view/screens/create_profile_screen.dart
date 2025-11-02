// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:country_picker/country_picker.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:swopband/controller/user_controller/UserController.dart';
import 'package:swopband/services/nfc_background_service.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';

import '../utils/images/iamges.dart';
import '../translations/app_strings.dart';
import 'bottom_nav/PurchaseScreen.dart';
import 'connect_swopband_screen.dart';
import 'AddLinkScreen.dart';
import '../../services/nfc_visibility_service.dart';

class CreateProfileScreen extends StatefulWidget {
  final dynamic userImage, name, email;
  const CreateProfileScreen({super.key, this.userImage, this.name, this.email});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController swopUserNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String _phoneNumber = '';
  Country _selectedCountry = Country.parse('GB');

  final FocusNode usernameFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode ageFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode bioFocus = FocusNode();

  final controller = Get.put(UserController());
  final NfcBackgroundService _nfcBackgroundService = NfcBackgroundService();

  final GlobalKey<_ImagePickerExampleState> _imagePickerKey =
  GlobalKey<_ImagePickerExampleState>();

  final bool _nfcInProgress = false;
  final String _nfcStatus = '';
  Timer? _nfcTimeoutTimer;
  bool _isCheckingNfcVisibility = false;

  // --- UI constants ---
  static const double _fieldHeight = 42.0;
  static const double _radius = 28.0;
  static const double _borderWidth = 1.5;
  static const Color _pageBg = Color(0xFFFFFAFA);

  TextStyle get _titleStyle => GoogleFonts.outfit(
    fontSize: 24,
    height: 29 / 24,
    fontWeight: FontWeight.w500, // reduced as requested
    letterSpacing: -0.2,
    color: Colors.black,
  );

  TextStyle get _hintStyle => GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: Colors.black,
  );

  TextStyle get _textStyle => GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: Colors.black,
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    isCollapsed: true,
    border: InputBorder.none,
    hintText: hint,
    hintStyle: _hintStyle,
    contentPadding: EdgeInsets.zero,
  );

  BoxDecoration get _fieldBox => BoxDecoration(
    color: _pageBg,
    borderRadius: BorderRadius.circular(_radius),
    border: Border.all(color: Colors.black, width: _borderWidth),
  );

  Widget _buildFieldShell({required Widget child, double? height}) => Container(
    height: height ?? _fieldHeight,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: _fieldBox,
    alignment: Alignment.center,
    child: child,
  );

  @override
  void initState() {
    super.initState();
    nameController.text = widget.name ?? '';
    emailController.text = widget.email ?? '';
    final rawName = (widget.name ?? '').toString();
    if (rawName.isNotEmpty) {
      final username =
      rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      swopUserNameController.text = username;
      if (username.isNotEmpty) {
        controller.checkUsernameAvailability(username);
      }
    }
  }

  @override
  void dispose() {
    usernameFocus.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    ageFocus.dispose();
    phoneFocus.dispose();
    bioFocus.dispose();

    _nfcTimeoutTimer?.cancel();
    _nfcTimeoutTimer = null;

    if (_nfcInProgress) {
      try {
        NfcManager.instance.stopSession();
      } catch (e) {
        log("[NFC] stopSession error in dispose: $e");
      }
      _nfcBackgroundService.resumeBackgroundOperations();
    }
    super.dispose();
  }

  bool _validateForm() {
    if (swopUserNameController.text.trim().isEmpty) {
      SnackbarUtil.showError('Please enter a username');
      return false;
    }
    if (nameController.text.trim().isEmpty) {
      SnackbarUtil.showError('Please enter your name');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      SnackbarUtil.showError('Please enter your email');
      return false;
    }
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      SnackbarUtil.showError('Please enter a valid email address');
      return false;
    }
    if (ageController.text.trim().isNotEmpty) {
      final age = int.tryParse(ageController.text.trim());
      if (age == null || age < 1 || age > 99) {
        SnackbarUtil.showError('Please enter a valid age (1-99)');
        return false;
      }
    }
    if (_phoneNumber.isEmpty || _phoneNumber.length < 7) {
      SnackbarUtil.showError('Please enter a valid phone number');
      return false;
    }
    return true;
  }

  Future<void> _handleConnectSwopband() async {
    if (!_validateForm()) return;
    if (swopUserNameController.text.trim().isNotEmpty) {
      await controller
          .checkUsernameAvailability(swopUserNameController.text.trim());
      await Future.delayed(const Duration(milliseconds: 250));
      if (controller.isUsernameAvailable.value == false) {
        SnackbarUtil.showError(
          controller.usernameMessage.value.isNotEmpty
              ? controller.usernameMessage.value
              : 'Username is not available. Please choose a different username.',
        );
        return;
      }
    }
    setState(() {
      _isCheckingNfcVisibility = true;
    });

    try {
      final showNfcStep = await NfcVisibilityService.shouldShowNfcConnectStep();
      if (!mounted) return;

      if (showNfcStep) {
        setState(() {
          _isCheckingNfcVisibility = false;
        });
        Get.to(
          () => ConnectSwopbandScreen(
            username: swopUserNameController.text,
            name: nameController.text,
            email: emailController.text,
            bio: bioController.text,
            age: ageController.text.trim().isNotEmpty
                ? int.tryParse(ageController.text.trim())
                : null,
            phone: _phoneNumber.isNotEmpty ? _phoneNumber : null,
            countryCode: _selectedCountry.phoneCode.isNotEmpty
                ? '+${_selectedCountry.phoneCode}'
                : null,
            userImage: widget.userImage,
            imagePickerKey: _imagePickerKey,
          ),
        );
        return;
      }

      await _completeSignupWithoutNfc();
    } catch (e, stackTrace) {
      log('Failed to determine NFC visibility: $e', stackTrace: stackTrace);
      SnackbarUtil.showError('Unable to continue. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNfcVisibility = false;
        });
      }
    }
  }

  Future<void> _completeSignupWithoutNfc() async {
    File? selectedFile;
    String profileImage = '';

    if (_imagePickerKey.currentState != null) {
      selectedFile =
          (_imagePickerKey.currentState as dynamic)?.getSelectedImageFile();
    }

    profileImage = await _getCurrentProfileImage();

    await controller.createUser(
      username: swopUserNameController.text,
      name: nameController.text,
      email: emailController.text,
      bio: bioController.text,
      age: ageController.text.trim().isNotEmpty
          ? int.tryParse(ageController.text.trim())
          : null,
      phone: _phoneNumber.isNotEmpty ? _phoneNumber : null,
      countryCode: _selectedCountry.phoneCode.isNotEmpty
          ? '+${_selectedCountry.phoneCode}'
          : null,
      profileFile: selectedFile,
      profileUrl: selectedFile == null ? profileImage : null,
      onSuccess: () {
        Get.offAll(() => const AddLinkScreen());
      },
    );
  }

  Future<String> _getCurrentProfileImage() async {
    if (widget.userImage != null && widget.userImage!.isNotEmpty) {
      return widget.userImage!;
    }

    if (_imagePickerKey.currentState != null) {
      File? selectedFile =
          (_imagePickerKey.currentState as dynamic)?.getSelectedImageFile();
      String? selectedUrl =
          (_imagePickerKey.currentState as dynamic)?.getCurrentImageUrl();

      if (selectedFile != null) {
        try {
          int fileSize = await selectedFile.length();
          if (fileSize <= 30 * 1024) {
            String? base64Image =
                await (_imagePickerKey.currentState as dynamic)
                    ?.getCurrentImageAsBase64();
            if (base64Image != null && base64Image.isNotEmpty) {
              return base64Image;
            }
          }
        } catch (e) {
          log('Error processing picked image: $e');
        }
      }

      if (selectedUrl != null && selectedUrl.isNotEmpty) {
        return selectedUrl;
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      resizeToAvoidBottomInset:
      true, // <-- important to allow body to shift for keyboard
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28)
                  .copyWith(bottom: 220),
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag, // <-- nice to have
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 52), // logo top spacing
                  Image.asset(MyImages.nameLogo, height: 43, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text(AppStrings.createProfile.tr,
                      style: _titleStyle, textAlign: TextAlign.center),

                  const SizedBox(height: 12), // reduced gap to avatar

                  // Avatar (130px, no outline)
                  ImagePickerExample(
                    key: _imagePickerKey,
                    profileImage: widget.userImage ?? "",
                  ),

                  const SizedBox(height: 24),

                  // Handle
                  _buildFieldShell(
                    child: TextField(
                      controller: swopUserNameController,
                      focusNode: usernameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => nameFocus.requestFocus(),
                      onChanged: (username) =>
                          controller.checkUsernameAvailability(username.trim()),
                      style: _textStyle,
                      decoration: _fieldDecoration("Enter your Swop Handle"),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Black availability chip — 28px height, wrap width
                  Obx(() {
                    final username = controller.swopUsername.value.trim();
                    if (username.isEmpty) return const SizedBox.shrink();

                    final ok = controller.isUsernameAvailable.value;
                    final msg = ok
                        ? (controller.usernameMessage.value.isNotEmpty
                        ? controller.usernameMessage.value
                        : "Username is available")
                        : (controller.usernameMessage.value.isNotEmpty
                        ? controller.usernameMessage.value
                        : "Swop already taken");

                    return Center(
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ok ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: ok ? Colors.greenAccent : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              msg,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: ok
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Full name
                  _buildFieldShell(
                    child: TextField(
                      controller: nameController,
                      focusNode: nameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => emailFocus.requestFocus(),
                      style: _textStyle,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z ]")),
                        LengthLimitingTextInputFormatter(25),
                      ],
                      decoration: _fieldDecoration("Enter Full Name"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email
                  _buildFieldShell(
                    child: TextField(
                      controller: emailController,
                      focusNode: emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => ageFocus.requestFocus(),
                      style: _textStyle,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z0-9@._-]"),
                        ),
                      ],
                      decoration: _fieldDecoration("Email Address"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Age
                  _buildFieldShell(
                    child: TextField(
                      controller: ageController,
                      focusNode: ageFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => phoneFocus.requestFocus(),
                      style: _textStyle,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(2),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _fieldDecoration("Age"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Country code + phone
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: _CountryChip(
                          height: _fieldHeight,
                          country: _selectedCountry,
                          textStyle: _textStyle,
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              onSelect: (c) => setState(() {
                                _selectedCountry = c;
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFieldShell(
                          child: TextField(
                            controller: phoneController,
                            focusNode: phoneFocus,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => bioFocus.requestFocus(),
                            style: _textStyle,
                            onChanged: (v) => _phoneNumber = v,
                            decoration: _fieldDecoration("Phone Number"),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  Container(
                    height: 100,
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                    decoration: _fieldBox,
                    child: Stack(
                      children: [
                        TextField(
                          controller: bioController,
                          focusNode: bioFocus,
                          maxLines: 3,
                          maxLength: 100,
                          style: _textStyle.copyWith(height: 1.25),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: "Add your bio",
                            hintStyle: _hintStyle,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 8,
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: bioController,
                            builder: (context, value, child) {
                              return Text(
                                "${value.text.length}/100",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Subtle fade to the fixed buttons
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00FFFAFA),
                          Color(0xFFFFFAFA),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed bottom buttons (keyboard-aware)
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // <-- lifts above keyboard
        ),
        child: SafeArea(
          top: false,
          child: Container(
            color: _pageBg,
            padding:
            const EdgeInsets.only(left: 28, right: 28, bottom: 20, top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final usernameUnavailable =
                      controller.isUsernameAvailable.value == false &&
                          controller.swopUsername.value.isNotEmpty;
                  final isBusy =
                      controller.isLoading.value || _isCheckingNfcVisibility;
                  return CustomButton(
                    text: AppStrings.connectSwopband.tr,
                    onPressed:
                        (usernameUnavailable || isBusy) ? null : _handleConnectSwopband,
                    buttonColor: Colors.black,
                    textColor: _pageBg,
                    isLoading: isBusy,
                  );
                }),
                const SizedBox(height: 10),
                CustomButton(
                  border: Colors.black,
                  buttonColor: _pageBg,
                  textColor: Colors.black,
                  text: AppStrings.purchaseSwopband.tr,
                  onPressed: () => Get.to(() => const PurchaseScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Country code chip
class _CountryChip extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;
  final double height;
  final TextStyle textStyle;

  const _CountryChip({
    required this.country,
    required this.onTap,
    required this.height,
    required this.textStyle,
  });

  static const double _radius = 28;
  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAFA),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: Colors.black, width: _borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('+${country.phoneCode}', style: textStyle),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.black),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Profile Image — 130px, no outline
class ImagePickerExample extends StatefulWidget {
  final String? profileImage;
  const ImagePickerExample({super.key, required this.profileImage});

  @override
  _ImagePickerExampleState createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  File? _selectedImageFile;
  String? _selectedImageUrl;
  bool _isLoadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if ((widget.profileImage ?? '').isNotEmpty) {
      _selectedImageUrl = widget.profileImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the literal bg color inside this widget to avoid const/scope errors.
    const Color kBg = Color(0xFFFFFAFA);

    return GestureDetector(
      onTap: () => _showImageSourceSheet(context),
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(
              color: kBg, // <-- const literal instead of _pageBg
              shape: BoxShape.circle,
              // no border outline as requested
            ),
            alignment: Alignment.center,
            child: CircleAvatar(
              backgroundColor: kBg, // <-- const literal instead of _pageBg
              radius: 65,
              backgroundImage: _isLoadingImage ? null : _getBackgroundImage(),
              onBackgroundImageError:
              _isLoadingImage ? null : (exception, stackTrace) {
                setState(() {
                  _selectedImageUrl = null;
                  _selectedImageFile = null;
                });
              },
              child: _isLoadingImage
                  ? const CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2.5,
              )
                  : null,
            ),
          ),
          if (!_isLoadingImage)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getBackgroundImage() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if ((_selectedImageUrl ?? '').isNotEmpty) {
      return NetworkImage(_selectedImageUrl!);
    } else {
      return const AssetImage("assets/images/img.png");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoadingImage = true);
    try {
      final storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        _showPermissionDialog('Storage permission is required to access photos.');
        return;
      }
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final size = await file.length();
        if (size > 15 * 1024 * 1024) {
          SnackbarUtil.showError('Image too large. Maximum allowed size is 15MB.');
          return;
        }
        setState(() {
          _selectedImageFile = file;
          _selectedImageUrl = null;
        });
        SnackbarUtil.showSuccess('Profile photo updated successfully');
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to pick image: $e');
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Change Profile Photo',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _sheetBtn(
              icon: Icons.camera_alt,
              text: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _sheetBtn(
              icon: Icons.photo_library,
              text: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            if (_selectedImageFile != null ||
                ((_selectedImageUrl ?? '').isNotEmpty))
              Column(
                children: [
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _sheetBtn(
                    icon: Icons.delete,
                    text: 'Remove Photo',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageUrl = null;
                      });
                      SnackbarUtil.showSuccess('Profile photo removed');
                    },
                  ),
                ],
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title:
      Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required', style: GoogleFonts.outfit()),
        content: Text(message, style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text('Open Settings', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  // Add missing methods that are expected by the NFC connection code
  String? getCurrentImageUrl() {
    return _selectedImageUrl;
  }

  File? getSelectedImageFile() {
    return _selectedImageFile;
  }

  Future<String?> getCurrentImageAsBase64() async {
    if (_selectedImageFile != null) {
      try {
        List<int> imageBytes = await _selectedImageFile!.readAsBytes();
        return base64Encode(imageBytes);
      } catch (e) {
        print('Error converting image to base64: $e');
        return null;
      }
    }
    return null;
  }
}
