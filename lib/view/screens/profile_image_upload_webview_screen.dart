import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:swopband/controller/user_controller/UserController.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/shared_pref/SharedPrefHelper.dart';
import '../widgets/custom_snackbar.dart';

class ProfileImageUploadWebViewScreen extends StatefulWidget {
  const ProfileImageUploadWebViewScreen({super.key});
  
  @override
  State<ProfileImageUploadWebViewScreen> createState() => _ProfileImageUploadWebViewScreenState();
}

class _ProfileImageUploadWebViewScreenState extends State<ProfileImageUploadWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    log("Opening profile image upload webview: https://profile.swopband.com/");
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Check if this is a response page with imageUrl
            _checkForImageUploadResponse();
          },
        ),
      )
      ..loadRequest(Uri.parse("https://profile.swopband.com/"));
  }

  // Check if the current page contains image upload response
  void _checkForImageUploadResponse() async {
    try {
      // Get the page content
      String pageContent = await _controller.runJavaScriptReturningResult('document.body.innerText') as String;
      log("Page content: $pageContent");
      
      // Check if the response contains imageUrl
      if (pageContent.contains('imageUrl') && pageContent.contains('Image uploaded successfully')) {
        // Try to parse the JSON response
        try {
          // Extract JSON from the page content
          int startIndex = pageContent.indexOf('{');
          int endIndex = pageContent.lastIndexOf('}');
          
          if (startIndex != -1 && endIndex != -1) {
            String jsonString = pageContent.substring(startIndex, endIndex + 1);
            Map<String, dynamic> response = json.decode(jsonString);
            
            String? imageUrl = response['imageUrl'];
            if (imageUrl != null && imageUrl.isNotEmpty) {
              log("✅ Image uploaded successfully! URL: $imageUrl");
              
              // Show success message
              _showSuccessDialog(imageUrl);
            }
          }
        } catch (e) {
          log("❌ Error parsing JSON response: $e");
        }
      }
    } catch (e) {
      log("❌ Error checking page content: $e");
    }
  }

  void _showSuccessDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Uploaded Successfully!'),
          content: const Text('Your profile image has been uploaded. Would you like to update your profile with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.back(); // Go back to update profile screen
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateProfileWithImage(imageUrl);
              },
              child: const Text('Update Profile'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfileWithImage(String imageUrl) async {
    try {
      // Get current user data
      final firebaseId = await SharedPrefService.getString('firebase_id');
      if (firebaseId != null) {
        // Fetch updated user data
        await userController.fetchUserByFirebaseId(firebaseId);
        
        // Update profile with the new image URL
        await userController.updateUser(
          username: AppConst.USER_NAME,
          name: AppConst.fullName,
          email: AppConst.EMAIL,
          bio: AppConst.BIO,
          profileUrl: imageUrl, // Use the new image URL
          profileFile: null,
          onSuccess: () {
            log("✅ Profile updated successfully with new image");
            _checkAuth();
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      log("❌ Error updating profile: $e");
      SnackbarUtil.showError("Failed to update profile: $e");
    }
  }


  Future<void> _checkAuth()async {
    final firebaseId = await SharedPrefService.getString('firebase_id');

    log("firebaseId  : $firebaseId");

    if (firebaseId != null && firebaseId.isNotEmpty) {
      await userController.fetchUserByFirebaseId(firebaseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: MyColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Upload Profile Image',
          style: AppTextStyles.large.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MyColors.textBlack,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MyColors.textBlack),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MyColors.textBlack),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: MyColors.textBlack,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Image Upload...',
                      style: AppTextStyles.medium.copyWith(
                        color: MyColors.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
