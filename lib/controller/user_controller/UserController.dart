import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/view/network/ApiUrls.dart';
import 'package:swopband/view/utils/app_constants.dart';
import 'package:swopband/view/utils/id_utils.dart';
import '../../view/network/ApiService.dart';
import '../../view/utils/shared_pref/SharedPrefHelper.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import 'package:swopband/view/screens/bottom_nav/BottomNavScreen.dart';
import 'package:http/http.dart' as http;

class UserController extends GetxController {
  var isLoading = false.obs;
  var fetchUserProfile = false.obs;
  var isUsernameAvailable = false.obs;
  var reviewLoader = false.obs;
  var usernameMessage = ''.obs;
  var swopUsername = ''.obs;

  Future<void> createUser({
    required String username,
    required String name,
    required String email,
    required String bio,
    int? age,
    String? phone,
    String? countryCode,
    String? profileUrl,
    File? profileFile,
    VoidCallback? onSuccess,
  }) async {
    isLoading.value = true;

    final Map<String, String> fields = {
      "username": username,
      "name": name,
      "email": email,
      "bio": bio,
    };
    if (age != null) {
      fields["age"] = age.toString();
    }
    if (phone != null && phone.isNotEmpty) {
      fields["phone_number"] = phone;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      fields["country_code"] = countryCode;
    }
    if (profileUrl != null && profileUrl.isNotEmpty) {
      fields["profile"] = profileUrl;
    }

    log("CREATE USER PARAMETER------>$fields");
    if (profileUrl != null) {
      print("Profile URL/Base64 length: ${profileUrl.length}");
    }

    if ((profileUrl ?? '').isNotEmpty) {
      if (profileUrl!.startsWith('data:image') ||
          profileUrl.startsWith('/9j/') ||
          profileUrl.startsWith('iVBOR')) {
        print("Profile is base64 encoded image");
        print("Base64 starts with: ${profileUrl.substring(0, 50)}...");
        print(
            "Base64 ends with: ...${profileUrl.substring(profileUrl.length - 50)}");
      } else if (profileUrl.startsWith('http')) {
        print("Profile is URL: $profileUrl");
      } else {
        print("Profile is empty or invalid");
      }
    } else {
      print("Profile is empty");
    }
    http.Response? response;
    if (profileFile != null) {
      response = await ApiService.multipartPost(
        ApiUrls.createUser,
        fields: fields,
        file: profileFile,
        fileFieldName: 'profile',
        filename: profileFile.path.split('/').last,
      );
    } else {
      response = await ApiService.post(ApiUrls.createUser, fields);
    }

    isLoading.value = false;
    log("CREATE USER RESPONSE------>${response?.body}");

    if (response == null) {
      SnackbarUtil.showError("No response from server");
      return;
    }

    try {
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userId = body['id'].toString();
        final message = body['message'] ?? "User created";

        await SharedPrefService.saveString('backend_user_id', userId);
        SnackbarUtil.showSuccess(message);
        if (onSuccess != null) onSuccess(); // callback e.g. navigation
            } else {
        // Check for field-specific validation errors first
        if (body['errors'] != null && body['errors']['fieldErrors'] != null) {
          final fieldErrors =
              body['errors']['fieldErrors'] as Map<String, dynamic>;

          // Check for name field error
          if (fieldErrors['name'] != null &&
              fieldErrors['name'] is List &&
              fieldErrors['name'].isNotEmpty) {
            final nameError = fieldErrors['name'][0];
            log("Name field error: $nameError");
            SnackbarUtil.showError(nameError);
            return;
          }

          // Check for username field error
          if (fieldErrors['username'] != null &&
              fieldErrors['username'] is List &&
              fieldErrors['username'].isNotEmpty) {
            final usernameError = fieldErrors['username'][0];
            log("Username field error: $usernameError");
            SnackbarUtil.showError(usernameError);
            return;
          }

          // Check for email field error
          if (fieldErrors['email'] != null &&
              fieldErrors['email'] is List &&
              fieldErrors['email'].isNotEmpty) {
            final emailError = fieldErrors['email'][0];
            log("Email field error: $emailError");
            SnackbarUtil.showError(emailError);
            return;
          }

          // Check for other field errors
          for (String field in fieldErrors.keys) {
            if (fieldErrors[field] is List && fieldErrors[field].isNotEmpty) {
              final fieldError = fieldErrors[field][0];
              log("Field error for $field: $fieldError");
              SnackbarUtil.showError(fieldError);
              return;
            }
          }
        }

        // Fallback to general error message
        final error =
            body['error'] ?? body['message'] ?? "Something went wrong";
        SnackbarUtil.showError(error);
        // If user already exists, navigate to BottomNavScreen
        if (error
            .toString()
            .toLowerCase()
            .contains('firebase id or email id already exist')) {
          final existingId = normalizeBackendUserId(body['id']) ??
              normalizeBackendUserId(body['id']?['id']);
          if (existingId != null && existingId.isNotEmpty) {
            await SharedPrefService.saveString('backend_user_id', existingId);
          }
          Get.offAll(() => BottomNavScreen());
        }
      }
    } catch (e) {
      print("❌ JSON parsing error: $e");
      print("❌ Response body: ${response.body}");
      SnackbarUtil.showError("Invalid response format: $e");
    }
  }

  Future<void> updateUser({
    required String username,
    required String name,
    required String email,
    required String bio,
    String? phone,
    String? countryCode,
    String? profileUrl,
    File? profileFile, // Keep for backward compatibility but won't be used
    VoidCallback? onSuccess,
  }) async {
    isLoading.value = true;

    // Get backend user ID for update
    final backendUserId = await SharedPrefService.getString('backend_user_id');
    log("🔗 Backend user ID: $backendUserId");
    if (backendUserId == null || backendUserId.isEmpty) {
      SnackbarUtil.showError("User ID not found. Please login again.");
      isLoading.value = false;
      return;
    }

    final Map<String, String> fields = {
      "username": username,
      "name": name,
      "email": email,
      "bio": bio,
    };

    // Add phone and country_code if provided
    if (phone != null && phone.isNotEmpty) {
      fields["phone_number"] = phone;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      fields["country_code"] = countryCode;
    }

    // Add profile_url if provided (imageUrl from /uploads/ API)
    if (profileUrl != null && profileUrl.isNotEmpty) {
      fields["profile_url"] = profileUrl.toString();
      log("🔗 Using profile URL from /uploads/ API : $profileUrl");
    }

    log("🔗 UPDATE USER PARAMETERS: $fields");
    log("🔗 BACKEND USER ID: $backendUserId");

    // Update profile using PUT request
    final updateUrl = "${ApiUrls.updateUser}$backendUserId";
    log("🔗 UPDATE URL: $updateUrl");

    final response = await ApiService.put(updateUrl, fields);

    isLoading.value = false;
    _handleUpdateResponse(
        response, username, name, email, bio, profileUrl, onSuccess);
  }

  void _handleUpdateResponse(
    http.Response? response,
    String username,
    String name,
    String email,
    String bio,
    String? finalProfileUrl,
    VoidCallback? onSuccess,
  ) {
    log("UPDATE USER RESPONSE------>${response?.body}");
    log("UPDATE USER STATUS CODE------>${response?.statusCode}");

    if (response == null) {
      SnackbarUtil.showError("No response from server");
      return;
    }

    try {
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = body['message'] ?? "Profile updated successfully";
        SnackbarUtil.showSuccess(message);

        // Update local constants with new values
        AppConst.USER_NAME = username;
        AppConst.fullName = name;
        AppConst.EMAIL = email;
        AppConst.BIO = bio;
        if (finalProfileUrl != null && finalProfileUrl.isNotEmpty) {
          AppConst.USER_PROFILE = finalProfileUrl;
        }

        if (onSuccess != null) onSuccess();
      } else {
        final error =
            body['error'] ?? body['message'] ?? "Something went wrong";
        SnackbarUtil.showError(
            "Update failed: $error (Status: ${response.statusCode})");

        // Log more details for debugging
        log("❌ Update failed with status: ${response.statusCode}");
        log("❌ Response body: ${response.body}");
        log("❌ Request URL: ${response.request?.url}");
        log("❌ Request method: ${response.request?.method}");
      }
    } catch (e) {
      print("❌ JSON parsing error: $e");
      print("❌ Response body: ${response.body}");
      SnackbarUtil.showError("Invalid response format: $e");
    }
  }

  Future<void> checkUsernameAvailability(String username) async {
    swopUsername.value = username; // Update instantly

    if (username.isEmpty) {
      isUsernameAvailable.value = false;
      usernameMessage.value = '';
      return;
    }

    final url = "${ApiUrls.checkUsername}$username";

    print("checkUsernameAvailability URL: $url");
    final response = await ApiService.get(url);
    print("checkUsernameAvailability Response: ${response?.statusCode}");
    print("checkUsernameAvailability Response Body: ${response?.body}");

    if (response != null && response.statusCode == 200) {
      print("checkUsernameAvailability Success: $response");

      final body = jsonDecode(response.body);
      isUsernameAvailable.value = body['status'] == true;
      usernameMessage.value = body['message'] ?? '';
      print("usernameMessage: ${body['message']}");
      print("isUsernameAvailable: ${body['status']}");
    } else {
      print("checkUsernameAvailability Error: ${response?.statusCode}");
      print("checkUsernameAvailability Error Body: ${response?.body}");
      isUsernameAvailable.value = false;
      usernameMessage.value = 'Something went wrong';
    }
  }

  Future<void> submitReviewRating(
      int rating, String review, BuildContext context,
      {VoidCallback? onSuccess}) async {
    reviewLoader.value = true;
    final mapData = {
      "stars": rating,
      "feedback": review,
    };

    log("REVIEW RATING PARAMETER------>$mapData");

    try {
      var response = await ApiService.post(ApiUrls.submitReview, mapData);
      log("REVIEW RATING RESPONSE------>${response?.body}");

      if (response == null) {
        SnackbarUtil.showError("No response from server");
        return;
      }

      // First check status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // Parse response body
          final data = json.decode(response.body);

          // Check if response contains success message
          if (data['message'] != null &&
              data['message'] == "Review submitted.") {
            // Call the success callback to clear the form
            onSuccess?.call();
            await _showSuccessDialog(context);
          } else {
            SnackbarUtil.showError("Unexpected response format");
          }
        } catch (e) {
          log('❌ Error parsing response: $e');
          SnackbarUtil.showError("Failed to parse server response");
        }
      } else {
        // Handle non-200 responses
        try {
          final errorData = json.decode(response.body);
          if (errorData['message']?['fieldErrors'] != null) {
            final errors =
                errorData['message']['fieldErrors'] as Map<String, dynamic>;
            errors.forEach((field, messages) {
              if (messages is List && messages.isNotEmpty) {
                SnackbarUtil.showError(messages.first);
              }
            });
          } else {
            SnackbarUtil.showError(
                errorData['message'] ?? "Failed to submit review");
          }
        } catch (e) {
          log('❌ Error parsing error response: $e');
          SnackbarUtil.showError(
              "Failed to submit review (${response.statusCode})");
        }
      }
    } catch (e) {
      log('❌ Error submitting review: $e');
      SnackbarUtil.showError("An error occurred while submitting review");
    } finally {
      reviewLoader.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchUserByFirebaseId(String firebaseId) async {
    fetchUserProfile.value = true;
    final url = Uri.parse('https://profile.swopband.com/users/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'firebase_id': firebaseId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];
        log("user detail---->", error: user);
        if (user is Map<String, dynamic>) {
          final normalizedId = normalizeBackendUserId(user['id']);
          if (normalizedId != null && normalizedId.isNotEmpty) {
            await SharedPrefService.saveString('backend_user_id', normalizedId);
            user['id'] = normalizedId;
          }

          final username = user['username'];
          final name = user['name'];
          final email = user['email'];
          final bio = user['bio'] ?? '';
          final profileUrl = user['profile_url'] ?? '';
          final phoneNumber = user['phone_number'] ?? '';
          final countryCode = user['country_code'] ?? '';

          log("📱 API Response - Phone Number: $phoneNumber");
          log("📱 API Response - Country Code: $countryCode");

          if (username != null) {
            AppConst.USER_NAME = username;
          }

          if (name != null) {
            AppConst.fullName = name;
          }

          if (email != null) {
            AppConst.EMAIL = email;
          }

          if (bio != null) {
            AppConst.BIO = bio;
          }

          if (profileUrl != null) {
            AppConst.USER_PROFILE = profileUrl;
          }

          if (phoneNumber != null) {
            AppConst.phoneNumber = phoneNumber;
          }

          if (countryCode != null) {
            AppConst.countryCode = countryCode.replaceFirst('+', '');
            log("Exist countryCode Data---------------$countryCode");
          }

          log("Exist User Data---------------$user");
          return user;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    } finally {
      fetchUserProfile.value = false;
    }
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Animated checkmark
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Success title
                const Text(
                  "Thank You!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Outfit",
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),

                // Success message
                Text(
                  "Your review has been submitted successfully",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontFamily: "Outfit",
                  ),
                ),
                const SizedBox(height: 20),

                // Close button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: "Outfit",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
