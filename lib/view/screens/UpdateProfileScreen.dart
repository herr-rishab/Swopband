import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:country_picker/country_picker.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:swopband/controller/user_controller/UserController.dart';
import 'package:swopband/view/utils/shared_pref/SharedPrefHelper.dart';
import 'package:swopband/view/network/ApiService.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_textfield.dart';
import '../utils/app_constants.dart';
import '../utils/images/iamges.dart';
import '../utils/app_colors.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController swopUserNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  // Phone number variables
  String _phoneNumber = '';
  Country _selectedCountry = Country.parse('GB');

  final controller = Get.put(UserController());
  String imageUrl = "";

  // Image picker related variables
  File? _selectedImageFile;
  String? _selectedImageUrl;
  bool _isLoadingImage = false;
  bool _isImageRemoved = false; // Flag to track if user removed the image
  final ImagePicker _picker = ImagePicker();

  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      await GoogleSignIn().signOut();

      print("✅ User successfully signed out.");

      // Navigate to login screen or initial screen
    } catch (e) {
      print("❌ Error signing out: $e");
    }
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

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      SnackbarUtil.showError('Please enter a valid email address');
      return false;
    }

    // Phone validation (required)
    if (_phoneNumber.isEmpty) {
      SnackbarUtil.showError('Please enter your phone number');
      return false;
    }

    if (_phoneNumber.length < 7) {
      SnackbarUtil.showError('Please enter a valid phone number');
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final firebaseId = await SharedPrefService.getString('firebase_id');

    log("firebaseId  : $firebaseId");

    if (firebaseId != null && firebaseId.isNotEmpty) {
      await controller.fetchUserByFirebaseId(firebaseId);
      imageUrl = sanitizeProfileUrl(AppConst.USER_PROFILE as String?);
      nameController.text = AppConst.fullName;
      bioController.text = AppConst.BIO;
      swopUserNameController.text = AppConst.USER_NAME;
      emailController.text = AppConst.EMAIL;

      // Initialize phone data from API response
      // Assuming the API response has phone_number and country_code fields
      // You may need to adjust these field names based on your actual API response
      if (AppConst.phoneNumber != null && AppConst.phoneNumber!.isNotEmpty) {
        _phoneNumber = AppConst.phoneNumber!;
        phoneController.text = AppConst.phoneNumber!;
      }
      if (AppConst.countryCode != null && AppConst.countryCode!.isNotEmpty) {
        // Parse the country code to set the selected country
        String countryCode = AppConst.countryCode!.replaceFirst('+', '');
        try {
          _selectedCountry = Country.parse(countryCode);
        } catch (e) {
          _selectedCountry = Country.parse('GB'); // Default fallback
        }
        log("_countryCode----${AppConst.countryCode}");
      }

      // Initialize image picker variables
      if (AppConst.USER_PROFILE.isNotEmpty) {
        _selectedImageUrl = AppConst.USER_PROFILE;
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_validateForm()) {
      return;
    }

    // Get current profile image URL
    String? profileUrl = _selectedImageUrl ?? AppConst.USER_PROFILE;

    log("🔗 Updating profile with imageUrl: $profileUrl");

    await controller.updateUser(
      username: swopUserNameController.text,
      name: nameController.text,
      email: emailController.text, // Use the email from form
      bio: bioController.text,
      phone: _phoneNumber.isNotEmpty ? _phoneNumber : null,
      countryCode: _selectedCountry.phoneCode.isNotEmpty
          ? '+${_selectedCountry.phoneCode}'
          : null,
      profileFile:
          null, // No file upload needed as image is already uploaded to API
      profileUrl: "",
      onSuccess: () {
        SnackbarUtil.showSuccess("Profile updated successfully!");
        Get.back(); // Go back to previous screen
      },
    );
  }

  // Method to get current profile image (selected file or existing image)
  Future<String> _getCurrentProfileImage() async {
    log("=== _getCurrentProfileImage called ===");

    // Use selected URL if available
    if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty) {
      log("✅ Using selected URL: $_selectedImageUrl");
      return _selectedImageUrl!;
    }

    // Final fallback to existing profile
    log("⚠️ No suitable image available, sending empty string");
    return "";
  }

  String sanitizeProfileUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (kIsWeb && url.startsWith('http://profile.swopband.com')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  // Build image picker widget
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _openImagePicker(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: MyColors.textWhite,
            backgroundImage: _isLoadingImage ? null : _getBackgroundImage(),
            onBackgroundImageError:
                (_isLoadingImage || _getBackgroundImage() == null)
                    ? null
                    : (exception, stackTrace) {
                        print('Error loading profile image: $exception');
                        // Fallback to default image on error
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
                : _buildProfileImageContent(),
          ),
          // Camera icon overlay to indicate it's clickable
          if (!_isLoadingImage)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
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

  // Open image picker for direct device upload
  void _openImagePicker(BuildContext context) {
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
            // Handle bar
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
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _buildOptionButton(
              context,
              icon: Icons.photo_library,
              text: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            // Only show remove option if there's an image
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
      leading: Icon(icon, color: MyColors.primaryColor),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _removeImage() {
    Navigator.pop(context);
    setState(() {
      _selectedImageFile = null;
      _selectedImageUrl = null;
      _isImageRemoved = true; // Mark that image has been removed
    });

    // Call API to remove image from server
    _removeImageFromAPI('');

    _showSuccessSnackbar('Profile photo removed');
  }

  Future<void> _removeImageFromAPI(String profileUrl) async {
    try {
      log('🗑️ Removing profile image via users/<userId> PUT with profile_url: null ...');

      final userId = await SharedPrefService.getString('backend_user_id');
      if (userId == null || userId.isEmpty) {
        SnackbarUtil.showError('User ID not found');
        return;
      }

      final url = 'https://profile.swopband.com/users/$userId';
      final body = {"profile_url": profileUrl.isEmpty ? null : profileUrl};

      final response = await ApiService.put(url, body);
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        _showSuccessSnackbar(
            'Profile photo ${profileUrl.isEmpty ? "removed" : "update"}');

        log('✅ Profile image  ${profileUrl.isEmpty ? "Removed" : "Add"} successfully');
      } else {
        log('❌ Failed to remove  ${profileUrl.isEmpty ? "Removed" : "Add"}. Status: ${response?.statusCode}, Body: ${response?.body}');
        SnackbarUtil.showError(
            'Failed to  ${profileUrl.isEmpty ? "Removed" : "Add"} image on server');
      }
    } catch (e) {
      log('❌ Error removing  ${profileUrl.isEmpty ? "Removed" : "Add"} from server: $e');
      SnackbarUtil.showError(
          'Failed to  ${profileUrl.isEmpty ? "Removed" : "Add"} image from server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Update your profile"),
      ),
      body: Obx(() {
        if (controller.fetchUserProfile.value) {
          return const Center(
              child: CircularProgressIndicator(
            color: Colors.black,
          ));
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(MyImages.nameLogo, height: 40),
                    const SizedBox(height: 10),
                    // Text(
                    //   "Update your profile",
                    //   style: AppTextStyles.large.copyWith(fontSize: 20),
                    //   textAlign: TextAlign.center,
                    // ),

                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    /*      Text(
                    AppStrings.createSwopHandle.tr,
                    style: AppTextStyles.large.copyWith(fontSize: 13,fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),*/
                    const SizedBox(height: 5),
                    myFieldAdvance(
                      readOnly: true,
                      onChanged: (username) {
                        controller.checkUsernameAvailability(username.trim());
                      },
                      context: context,
                      controller: swopUserNameController,
                      hintText: "Enter username",
                      inputType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      fillColor: MyColors.textWhite,
                      textBack: MyColors.textWhite,
                    ),

                    /*SizedBox(height: 8),
                  Obx(() {
                    final username = controller.swopUsername.value.trim();
                    if (username.isEmpty) return const SizedBox(); // Hide when empty

                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: MyColors.textBlack,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          //height: 30,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              username,
                              style: AppTextStyles.small.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: MyColors.textWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.usernameMessage.value,
                          style: AppTextStyles.small.copyWith(
                            color: controller.isUsernameAvailable.value ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }),*/

                    const SizedBox(height: 15),
                    myFieldAdvance(
                      context: context,
                      controller: nameController,
                      hintText: "Enter Full Name",
                      inputType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      fillColor: MyColors.textWhite,
                      textBack: MyColors.textWhite,
                    ),
                    const SizedBox(height: 20),
                    myFieldAdvance(
                      readOnly: true,
                      context: context,
                      controller: emailController,
                      hintText: "Email",
                      inputType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      fillColor: MyColors.textWhite,
                      textBack: MyColors.textWhite,
                    ),
                    const SizedBox(height: 15),
                    // Phone number field with separated country code and phone number
                    Row(
                      children: [
                        // Country code field with flag
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                onSelect: (Country country) {
                                  setState(() {
                                    _selectedCountry = country;
                                  });
                                },
                                showPhoneCode: true,
                              );
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: MyColors.textWhite,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedCountry.flagEmoji,
                                      style: const TextStyle(
                                          fontSize: 20, fontFamily: "Outfit"),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+${_selectedCountry.phoneCode}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Outfit",
                                        color: MyColors.textBlack,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: MyColors.textBlack,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Space between fields
                        // Phone number field
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              hintText: "Phone Number",
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Outfit",
                                color: MyColors.textBlack,
                                decoration: TextDecoration.none,
                                wordSpacing: 1.2,
                              ),
                              filled: true,
                              fillColor: MyColors.textWhite,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 1.2,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(28)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyColors.textBlack,
                                  width: 1.2,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(28)),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(28)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 7) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _phoneNumber = value;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      maxLength: 100,
                      controller: bioController,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        counterText: '', // default counter hatane ke liye
                        counter: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: bioController,
                          builder: (context, value, child) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 16.0, top: 8),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  "${value.text.length}/100",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: "Outfit",
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // contentPadding: const EdgeInsets.only(
                        //   top: 40,
                        //   left: 20,
                        //   right: 20,
                        //   bottom: 20,
                        // ),
                        hintText: "Add your bio",

                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontFamily: "Outfit",
                          color: MyColors.textBlack,
                          decoration: TextDecoration.none,
                          wordSpacing: 1.2,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: "Update Profile",
                      onPressed: () {
                        _updateProfile();
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Image picker methods
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Check permissions based on source
      if (source == ImageSource.camera) {
        var cameraStatus = await Permission.camera.status;
        log('📷 Camera permission status: $cameraStatus');
        // Uncomment if you want to enforce camera permission check
        // if (cameraStatus != PermissionStatus.granted) {
        //   cameraStatus = await Permission.camera.request();
        //   if (cameraStatus != PermissionStatus.granted) {
        //     _showPermissionDialog('Camera permission is required to take photos. Please enable it in settings.');
        //     return;
        //   }
        // }
      } else {
        var photosStatus = await Permission.photos.status;
        log('📸 Photos permission status: $photosStatus');
        // Uncomment if you want to enforce gallery permission check
        // if (photosStatus != PermissionStatus.granted) {
        //   photosStatus = await Permission.photos.request();
        //   if (photosStatus != PermissionStatus.granted) {
        //     _showPermissionDialog('Photos permission is required to access gallery. Please enable it in settings.');
        //     return;
        //   }
        // }
      }

      setState(() {
        _isLoadingImage = true;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      log('📱 Opening ${source == ImageSource.camera ? 'camera' : 'gallery'}...');

      // ✅ Increased quality & resolution (no more 200x200 tiny image)
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90, // high quality (90%)
        maxWidth: 1920, // Full HD width
        maxHeight: 1920, // Full HD height
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        // ✅ Validate file size (allow up to 15MB)
        int fileSize = await file.length();
        double sizeMB = fileSize / (1024 * 1024);
        log('Selected image size: $fileSize bytes (${sizeMB.toStringAsFixed(2)} MB)');
        if (fileSize > 15 * 1024 * 1024) {
          _showErrorSnackbar('Image too large. Maximum allowed size is 15MB.');
          return;
        }

        // ✅ Validate and convert file type if needed
        File? processedFile = await _processImageFile(file);
        if (processedFile == null) {
          _showErrorSnackbar('Failed to process image. Please try again.');
          return;
        }

        setState(() {
          _selectedImageFile = processedFile;
          _selectedImageUrl = null; // Clear URL since we have a file
          _isImageRemoved =
              false; // Reset remove flag when new image is selected
        });

        // ✅ Upload image to API
        await _uploadImageToAPI(processedFile);

        log('✅ Image selected and stored: ${processedFile.path}');
      } else {
        log('No image selected.');
        _showErrorSnackbar('No image selected. Please try again.');
      }
    } catch (e) {
      log('❌ Error picking image: $e');

      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        _showPermissionDialog(
            'Permission denied. Please enable camera/photos permission in settings.');
      } else if (e.toString().contains('camera') ||
          e.toString().contains('Camera')) {
        _showErrorSnackbar(
            'Camera not available. Please check if camera is working properly.');
      } else {
        _showErrorSnackbar('Failed to pick image: $e');
      }
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<File?> _processImageFile(File originalFile) async {
    try {
      // Get file extension
      String filePath = originalFile.path;
      String extension = filePath.split('.').last.toLowerCase();

      log('Original file extension: $extension');

      // Check if file is already in supported format
      if (['jpg', 'jpeg', 'png', 'heic'].contains(extension)) {
        log('✅ File is already in supported format: $extension');
        return originalFile;
      }

      // For unsupported formats, show error and ask user to select supported format
      if (extension == 'webp' || extension == 'gif' || extension == 'bmp') {
        _showErrorSnackbar(
            'Please select JPEG, PNG, or HEIC format. WebP, GIF, and BMP are not supported.');
        return null;
      }

      // If we can't determine format, try to proceed (might be a valid image)
      log('⚠️ Unknown file extension: $extension, attempting to proceed');
      return originalFile;
    } catch (e) {
      log('❌ Error processing image file: $e');
      return null;
    }
  }

  Future<void> _uploadImageToAPI(File imageFile) async {
    try {
      setState(() {
        _isLoadingImage = true;
      });

      log('📤 Starting image upload to /uploads/ endpoint...');

      // Create multipart request to the correct endpoint
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://profile.swopband.com/uploads/'),
      );

      // Add image file with proper extension and content type
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      // Determine file extension from the actual file
      String filePath = imageFile.path;
      String extension = filePath.split('.').last.toLowerCase();

      // Ensure we have a valid extension for the API
      if (!['jpg', 'jpeg', 'png', 'heic'].contains(extension)) {
        extension = 'jpg'; // Default to jpg if extension is not supported
      }

      // Determine content type based on file extension
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'heic':
          contentType = 'image/heic';
          break;
        default:
          contentType = 'image/jpeg';
      }

      // Try different field names that the API might expect
      String fieldName = 'profile'; // Default field name

      var multipartFile = http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      log('📤 Sending request with file: ${multipartFile.filename}');
      log('📤 Content type: $contentType');
      log('📤 File extension: $extension');
      log('📤 Field name: $fieldName');
      log('📤 File size: $length bytes');

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      log('📡 Upload response status: ${response.statusCode}');
      log('📡 Upload response body: $responseData');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);

        // Extract imageUrl from the expected response format
        String? imageUrl = jsonResponse['imageUrl'];
        String? fileName = jsonResponse['fileName'];
        String? message = jsonResponse['message'];

        log('✅ Image uploaded successfully!');
        log('📁 File name: $fileName');
        log('🔗 Image URL: $imageUrl');
        log('💬 Message: $message');

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // First update local state, then call API to update profile with the new URL
          setState(() {
            _selectedImageUrl = imageUrl;
            _isImageRemoved = false; // Reset remove flag when image is uploaded
          });
          log('✅ Image URL set in state: $_selectedImageUrl');

          // Call update user immediately with the fresh imageUrl
          _removeImageFromAPI(imageUrl);
          //
        } else {
          log('❌ No imageUrl in response');
          _showErrorSnackbar('Upload successful but no image URL received');
        }
      } else {
        log('❌ Upload failed: ${response.statusCode} - $responseData');

        // Try to parse error response
        try {
          var jsonResponse = json.decode(responseData);
          String errorMessage =
              jsonResponse['message'] ?? 'Failed to upload image';

          if (errorMessage.contains('Invalid file type')) {
            // Try with different field names
            log('🔄 Trying with different field names...');
            bool success = await _tryAlternativeFieldNames(
                imageFile, extension, contentType);
            if (success) {
              return; // Success with alternative field name
            }
            errorMessage = 'Please select JPEG, PNG, or HEIC format only.';
          }

          _showErrorSnackbar(errorMessage);
        } catch (e) {
          _showErrorSnackbar('Failed to upload image (${response.statusCode})');
        }
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
      // _showErrorSnackbar('Error uploading image: $e');
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Widget? _buildProfileImageContent() {
    // Show profile image content when not loading
    if (_selectedImageFile != null ||
        (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty) ||
        (!_isImageRemoved && AppConst.USER_PROFILE.isNotEmpty)) {
      return null; // Let backgroundImage handle the display
    } else {
      // Show default profile icon when no image
      return Image.asset(
        "assets/images/img.png",
      );
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
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getBackgroundImage() {
    // Priority: Selected file > Selected URL > Original profile image (only if not removed) > Default image
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty) {
      return NetworkImage(_selectedImageUrl!);
    } else if (!_isImageRemoved && AppConst.USER_PROFILE.isNotEmpty) {
      // Only show original profile image if it hasn't been removed
      return NetworkImage(AppConst.USER_PROFILE);
    } else {
      return null; // Return null to show default icon instead of asset image
    }
  }

  void _showErrorSnackbar(String message) {
    SnackbarUtil.showError(message);
  }

  void _showSuccessSnackbar(String message) {
    SnackbarUtil.showSuccess(message);
  }

  // Method to try alternative field names if the first attempt fails
  Future<bool> _tryAlternativeFieldNames(
      File imageFile, String extension, String contentType) async {
    List<String> alternativeFieldNames = ['image', 'file', 'upload', 'photo'];

    for (String fieldName in alternativeFieldNames) {
      try {
        log('🔄 Trying field name: $fieldName');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://profile.swopband.com/uploads/'),
        );

        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          fieldName,
          stream,
          length,
          filename:
              'profile_${DateTime.now().millisecondsSinceEpoch}.$extension',
          contentType: MediaType.parse(contentType),
        );

        request.files.add(multipartFile);

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        log('📡 Alternative field "$fieldName" response status: ${response.statusCode}');
        log('📡 Alternative field "$fieldName" response body: $responseData');

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(responseData);
          String? imageUrl = jsonResponse['imageUrl'];

          if (imageUrl != null && imageUrl.isNotEmpty) {
            setState(() {
              _selectedImageUrl = imageUrl;
              _isImageRemoved =
                  false; // Reset remove flag when image is uploaded
            });

            log('✅ Success with field name: $fieldName');
            log('✅ Image URL: $imageUrl');
            _showSuccessSnackbar('Image uploaded successfully!');
            return true;
          }
        }
      } catch (e) {
        log('❌ Error with field name $fieldName: $e');
      }
    }

    log('❌ All alternative field names failed');
    return false;
  }
}
