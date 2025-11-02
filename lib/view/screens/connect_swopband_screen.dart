import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/controller/user_controller/UserController.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import 'package:swopband/services/nfc_background_service.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/images/iamges.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';
import '../translations/app_strings.dart';
import 'FaqScreen.dart';
import 'AddLinkScreen.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectSwopbandScreen extends StatefulWidget {
  final String username;
  final String name;
  final String email;
  final String bio;
  final int? age;
  final String? phone;
  final String? countryCode;
  final String? userImage;
  final GlobalKey imagePickerKey;

  const ConnectSwopbandScreen({
    Key? key,
    required this.username,
    required this.name,
    required this.email,
    required this.bio,
    this.age,
    this.phone,
    this.countryCode,
    this.userImage,
    required this.imagePickerKey,
  }) : super(key: key);

  @override
  State<ConnectSwopbandScreen> createState() => _ConnectSwopbandScreenState();
}

class _ConnectSwopbandScreenState extends State<ConnectSwopbandScreen> {
  final controller = Get.put(UserController());
  final NfcBackgroundService _nfcBackgroundService = NfcBackgroundService();

  bool _nfcInProgress = false;
  String _nfcStatus = '';
  Timer? _nfcTimeoutTimer;

  @override
  void dispose() {
    _nfcTimeoutTimer?.cancel();
    _nfcTimeoutTimer = null;

    if (_nfcInProgress) {
      try {
        NfcManager.instance.stopSession();
      } catch (e) {
        log("[NFC] Error stopping session in dispose: $e");
      }
      _nfcBackgroundService.resumeBackgroundOperations();
      log("[NFC] Background NFC operations resumed in dispose");
    }
    super.dispose();
  }

  Future<String> _getCurrentProfileImage() async {
    log("=== _getCurrentProfileImage called ===");

    if (widget.userImage != null && widget.userImage!.isNotEmpty) {
      log("✅ Using auth image URL (most reliable): ${widget.userImage}");
      return widget.userImage!;
    }

    if (widget.imagePickerKey.currentState != null) {
      File? selectedFile = (widget.imagePickerKey.currentState as dynamic)
          ?.getSelectedImageFile();
      String? selectedUrl =
      (widget.imagePickerKey.currentState as dynamic)?.getCurrentImageUrl();

      if (selectedFile != null) {
        try {
          int fileSize = await selectedFile.length();
          log("Selected file size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)");
          if (fileSize <= 30 * 1024) {
            String? base64Image =
            await (widget.imagePickerKey.currentState as dynamic)
                ?.getCurrentImageAsBase64();
            if (base64Image != null && base64Image.isNotEmpty) {
              log("✅ Sending small picked image as base64 (${base64Image.length} chars)");
              return base64Image;
            }
          } else {
            log("⚠️ File too large for base64 (${(fileSize / 1024).toStringAsFixed(2)} KB), skipping picked image");
          }
        } catch (e) {
          log("❌ Error processing picked file: $e");
        }
      }

      if (selectedUrl != null && selectedUrl.isNotEmpty) {
        log("✅ Using selected URL: $selectedUrl");
        return selectedUrl;
      }
    }

    log("⚠️ No suitable image available, sending empty string");
    return "";
  }

  Future<void> _startNfcSessionAndWrite() async {
    log("[NFC] Calling controller.createUser()");
    log("[NFC] Starting NFC session and write process...");
    setState(() {
      _nfcStatus = "Hold your iPhone near the Swopband ring...";
      _nfcInProgress = true;
    });

    _nfcBackgroundService.pauseBackgroundOperations();

    _nfcTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_nfcInProgress) {
        log("[NFC] Timeout reached, stopping NFC session");
        setState(() {
          _nfcStatus = "NFC connection timeout. Please try again.";
          _nfcInProgress = false;
        });
        try {
          NfcManager.instance.stopSession();
        } catch (e) {
          log("[NFC] Error stopping session on timeout: $e");
        }
        if (Platform.isAndroid && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _nfcBackgroundService.resumeBackgroundOperations();
        log("[NFC] Background NFC operations resumed after timeout");
      }
    });

    Platform.isAndroid
        ? showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.nfc,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Connect to Swopband",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Outfit",
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Hold your device near the Swopband ring to connect...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: "Outfit",
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CupertinoActivityIndicator(
                    color: MyColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    log("[NFC] User cancelled NFC session.");
                    try {
                      NfcManager.instance.stopSession();
                    } catch (e) {
                      log("[NFC] Error stopping session: $e");
                    }
                    Navigator.of(context).pop();
                    setState(() {
                      _nfcStatus = "";
                      _nfcInProgress = false;
                    });
                    _nfcBackgroundService.resumeBackgroundOperations();
                    log("[NFC] Background NFC operations resumed after user cancellation");
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontFamily: "Outfit",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    )
        : const SizedBox();

    try {
      log("[NFC] Calling NfcManager.instance.startSession()");
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        alertMessage: "Hold your device near the Swopband ring to connect",
        onDiscovered: (NfcTag tag) async {
          log("[NFC] Tag detected: $tag");

          var ndef = Ndef.from(tag);
          if (ndef == null) {
            log("[NFC] Tag is NOT NDEF compatible.");
            NfcManager.instance
                .stopSession(errorMessage: 'This tag is not NDEF compatible.');

            setState(() {
              _nfcStatus = "Tag not NDEF compatible.";
              _nfcInProgress = false;
            });
            SnackbarUtil.showError("Tag is not NDEF compatible.");
            Platform.isAndroid ? Navigator.of(context).pop() : null;
            _nfcBackgroundService.resumeBackgroundOperations();
            return;
          }

          log("[NFC] Tag is NDEF compatible.");
          if (!ndef.isWritable) {
            log("[NFC] Tag is NOT writable.");
            NfcManager.instance
                .stopSession(errorMessage: 'This tag is not writable.');
            setState(() {
              _nfcStatus = "Tag is not writable.";
              _nfcInProgress = false;
            });
            SnackbarUtil.showError("Tag is not writable.");
            Platform.isAndroid ? Navigator.of(context).pop() : null;
            _nfcBackgroundService.resumeBackgroundOperations();
            return;
          }

          log("[NFC] Tag is writable. Preparing to write...");
          try {
            String swopHandleUrl =
                "https://profile.swopband.com/${widget.username}";
            log("[NFC] Writing URL to tag: $swopHandleUrl");
            await ndef.write(
                NdefMessage([NdefRecord.createUri(Uri.parse(swopHandleUrl))]));
            log("[NFC] Write successful, stopping NFC session.");
            _nfcTimeoutTimer?.cancel();
            _nfcTimeoutTimer = null;

            NfcManager.instance.stopSession();
            setState(() {
              _nfcStatus = "Successfully connected and written!";
              _nfcInProgress = false;
            });
            SnackbarUtil.showSuccess("Swopband connected successfully!");

            Platform.isAndroid ? Navigator.of(context).pop() : null;

            log("[NFC] Calling controller.createUser()");
            File? selectedFile = (widget.imagePickerKey.currentState as dynamic)
                ?.getSelectedImageFile();
            String profileImage = await _getCurrentProfileImage();
            await controller.createUser(
              username: widget.username,
              name: widget.name,
              email: widget.email,
              bio: widget.bio,
              age: widget.age,
              phone: widget.phone,
              countryCode: widget.countryCode,
              profileFile: selectedFile,
              profileUrl: selectedFile == null ? profileImage : null,
              onSuccess: () {
                log("[NFC] User created successfully, navigating to AddLinkScreen.");
                _nfcBackgroundService.resumeBackgroundOperations();
                Get.offAll(() => const AddLinkScreen());
              },
            );
          } catch (e) {
            log("[NFC] Error during write: $e");
            _nfcTimeoutTimer?.cancel();
            _nfcTimeoutTimer = null;

            NfcManager.instance.stopSession(errorMessage: e.toString());
            setState(() {
              _nfcStatus = "Write failed: $e";
              _nfcInProgress = false;
            });
            SnackbarUtil.showError("Failed to write to tag: $e");
            Platform.isAndroid ? Navigator.of(context).pop() : null;
            _nfcBackgroundService.resumeBackgroundOperations();
          }
        },
        onError: (error) async {
          log("[NFC] NFC session error: $error");

          if (error.toString().contains('cancelled') ||
              error.toString().contains('canceled') ||
              error.toString().contains('user') ||
              error.toString().contains('User')) {
            log("[NFC] User cancelled default NFC popup");
            setState(() {
              _nfcStatus = "NFC connection cancelled by user";
              _nfcInProgress = false;
            });
            if (Platform.isAndroid && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            _nfcBackgroundService.resumeBackgroundOperations();
            log("[NFC] Background NFC operations resumed after user cancellation");
            return;
          }

          log("[NFC] Other NFC error: $error");
          setState(() {
            _nfcStatus = "NFC error: $error";
            _nfcInProgress = false;
          });
          SnackbarUtil.showError("NFC error: $error");

          if (Platform.isAndroid && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          _nfcBackgroundService.resumeBackgroundOperations();
          log("[NFC] Background NFC operations resumed after NFC error");
        },
      );
    } catch (e) {
      log("[NFC] Failed to start NFC session: $e");
      setState(() {
        _nfcStatus = "Failed to start NFC session: $e";
        _nfcInProgress = false;
      });
      SnackbarUtil.showError("Failed to start NFC session: $e");
      if (Platform.isAndroid && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _nfcBackgroundService.resumeBackgroundOperations();
      log("[NFC] Background NFC operations resumed after session start error");
    }
  }

  static const double _baseW = 402.0;
  static const double _baseH = 858.0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFAFA),
        body: LayoutBuilder(
          builder: (context, c) {
            final double sx = c.maxWidth / _baseW;
            final double scale = sx;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  alignment: Alignment.topLeft,
                  scale: scale,
                  child: SizedBox(
                    width: _baseW,
                    height: _baseH,
                    child: _FigmaConnectRingLayer(
                      startNfc: _startNfcSessionAndWrite,
                      nfcInProgress: _nfcInProgress,
                      nfcStatus: _nfcStatus,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildInstructionItem(String text, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: 60,
            width: 60,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaConnectRingLayer extends StatelessWidget {
  final VoidCallback startNfc;
  final bool nfcInProgress;
  final String nfcStatus;

  const _FigmaConnectRingLayer({
    required this.startNfc,
    required this.nfcInProgress,
    required this.nfcStatus,
  });

  TextStyle get _titleStyle => const TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 29 / 24,
    letterSpacing: -0.48,
    color: Colors.black,
  );


  TextStyle get _bodyStyle => const TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 19 / 14,
    color: Colors.black,
  );


  @override
  Widget build(BuildContext context) {
    const double _titleTop = 160 - 9.5;
    const double _ringTop = 168 + 9.5;

    return Stack(
      children: [
        const Positioned(
          left: 0,
          top: 0,
          width: 402,
          height: 54,
          child: ColoredBox(color: Color(0xFFFFFAFA)),
        ),
        const Positioned(
          left: 94,
          top: 113,
          width: 215,
          height: 43,
          child: _LogoImage(),
        ),
        Positioned(
          left: 200,
          top: _titleTop,
          width: 344,
          height: 77,
          child: Transform.translate(
            offset: const Offset(-172, 0),
            child: Center(
              child: Text(
                AppStrings.connectYourSwopband.tr,
                textAlign: TextAlign.center,
                style: _titleStyle,
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 319,
          width: 344,
          height: 377,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        Positioned(
          left: 200,
          top: 354.89,
          width: 344,
          height: 28.053,
          child: Transform.translate(
            offset: const Offset(-172, 0),
            child: Text(
              AppStrings.connectingYourBand.tr,
              textAlign: TextAlign.center,
              style: _titleStyle,
            ),
          ),
        ),
        Positioned(
          left: 56.43,
          top: 396.94,
          width: 51.144,
          height: 51.144,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Image.asset(MyImages.tr1mg, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 119,
          top: 400.26,
          width: 234,
          height: 64.813,
          child: Text(AppStrings.tapConnectInstruction.tr, style: _bodyStyle),
        ),
        Positioned(
          left: 56.43,
          top: 476.26,
          width: 51.144,
          height: 51.144,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Image.asset(MyImages.tr2mg, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 119,
          top: 479.58,
          width: 237,
          height: 67.715,
          child: Text(AppStrings.keepPositionInstruction.tr, style: _bodyStyle),
        ),
        Positioned(
          left: 56.43,
          top: 552.68,
          width: 51.144,
          height: 51.144,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Image.asset(MyImages.tr3mg, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 119,
          top: 556.0,
          width: 237,
          height: 67.715,
          child: Text(AppStrings.readyToScanInstruction.tr, style: _bodyStyle),
        ),
        Positioned(
          left: 38,
          top: 629,
          width: 324,
          height: 55,
          child: AbsorbPointer(
            absorbing: nfcInProgress,
            child: SizedBox(
              width: 324,
              height: 55,
              child: CustomButton(
                text: AppStrings.connectYourSwopbandButton.tr,
                onPressed: startNfc,
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 714,
          width: 344,
          height: 55,
          child: SizedBox(
            width: 344,
            height: 55,
            child: CustomButton(
              buttonColor: MyColors.textBlack,
              textColor: MyColors.textWhite,
              text: AppStrings.faqTroubleshooting.tr,
              onPressed: () => Get.to(() => const FAQScreen()),
            ),
          ),
        ),
        Positioned(
          left: 130,
          top: 858,
          width: 143,
          height: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
        Positioned(
          left: 49,
          top: _ringTop,
          width: 306.293,
          height: 213,
          child: IgnorePointer(
            child: Image.asset(
              MyImages.ringImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (nfcStatus.isNotEmpty)
          const Positioned(left: 0, top: 880, right: 0, child: SizedBox.shrink()),
      ],
    );
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(MyImages.nameLogo, fit: BoxFit.contain);
  }
}

class ImagePickerExample extends StatefulWidget {
  final String? profileImage;

  ImagePickerExample({super.key, required this.profileImage});

  @override
  _ImagePickerExampleState createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  File? _selectedImageFile;
  String? _selectedImageUrl;
  bool _isImageFromAuth = true;
  bool _isLoadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.profileImage != null && widget.profileImage!.isNotEmpty) {
      _selectedImageUrl = widget.profileImage;
      _isImageFromAuth = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: MyColors.primaryColor.withOpacity(0.1),
            backgroundImage: _isLoadingImage ? null : _getBackgroundImage(),
            onBackgroundImageError: _isLoadingImage
                ? null
                : (exception, stackTrace) {
              print('Error loading profile image: $exception');
              setState(() {
                _selectedImageUrl = null;
                _selectedImageFile = null;
              });
            },
            child: _isLoadingImage
                ? const CircularProgressIndicator(
              color: MyColors.primaryColor,
              strokeWidth: 3,
            )
                : null,
          ),
          if (!_isLoadingImage)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MyColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getBackgroundImage() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty) {
      return NetworkImage(_selectedImageUrl!);
    } else {
      return const AssetImage("assets/images/img.png") as ImageProvider;
    }
  }

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

  void _showImageSourceSheet(BuildContext context) async {
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
            const Text(
              'Change Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "Outfit",
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionButton(
              context,
              icon: Icons.camera_alt,
              text: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage1(ImageSource.camera);
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _buildOptionButton(
              context,
              icon: Icons.photo_library,
              text: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage1(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            if (_selectedImageFile != null ||
                (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty))
              Column(
                children: [
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildOptionButton(
                    context,
                    icon: Icons.delete,
                    text: 'Remove Photo',
                    onTap: _removeImage,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontFamily: "Outfit",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context, {
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: MyColors.accentColor),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _removeImage() {
    Navigator.pop(context);
    setState(() {
      _selectedImageFile = null;
      _selectedImageUrl = null;
      _isImageFromAuth = false;
    });
    _showSuccessSnackbar('Profile photo removed');
  }

  Future<void> _pickImage1(ImageSource source) async {
    setState(() {
      _isLoadingImage = true;
    });

    try {
      if (source == ImageSource.camera) {
        var cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          _showPermissionDialog(
              'Camera permission is required to take photos.');
          return;
        }
      } else {
        var storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          _showPermissionDialog(
              'Storage permission is required to access photos.');
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        int fileSize = await file.length();
        double sizeInMB = fileSize / (1024 * 1024);
        print(
            'Selected image size: $fileSize bytes (${sizeInMB.toStringAsFixed(2)} MB)');

        if (fileSize > 15 * 1024 * 1024) {
          _showErrorSnackbar('Image too large. Maximum allowed size is 15MB.');
          return;
        }

        setState(() {
          _selectedImageFile = file;
          _selectedImageUrl = null;
          _isImageFromAuth = false;
        });

        _showSuccessSnackbar('Profile photo updated successfully');
        print('✅ Image selected and stored: ${pickedFile.path}');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorSnackbar('Failed to pick image: $e');
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    SnackbarUtil.showError(message);
  }

  void _showSuccessSnackbar(String message) {
    SnackbarUtil.showSuccess(message);
  }
}