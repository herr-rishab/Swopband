import 'dart:developer';
import 'dart:io' show Platform;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:swopband/view/network/ApiService.dart';
import 'package:swopband/view/screens/PrivacyPolicyScreen.dart';
import 'package:swopband/view/screens/UpdateProfileScreen.dart';
import 'package:swopband/view/widgets/feedback_modal.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../../controller/recent_swoppers_controller/RecentSwoppersController.dart';
import 'FaqScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/shared_pref/SharedPrefHelper.dart';
import 'package:swopband/view/screens/welcome_screen.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import 'bottom_nav/PurchaseScreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---- DESIGN CONSTANTS ----
  static const double _hPad = 18;

  // Pills
  static const double _pillH = 56;
  static const double _pillR = 26;

  // Cards / rows
  static const double _cardR = 24;
  static const double _rowH  = 40;   // ↓ tighter between options (was 44)

  // Gaps
  static const double _gapS  = 10;
  static const double _gapM  = 16;
  static const double _gapL  = 22;

  // Title spacing
  static const double _titleTopGap = 28;
  static const double _titleBottomGap = 26;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: _titleTopGap),

              // TITLE
              Text(
                'Settings',
                textAlign: TextAlign.center,
                style: AppTextStyles.large.copyWith(
                  fontFamily: 'Outfit',
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: MyColors.textBlack,
                ),
              ),

              const SizedBox(height: _titleBottomGap),

              // WHITE PILL (weight down one level to w400)
              _Pill(
                height: _pillH,
                radius: _pillR,
                fill: MyColors.textWhite,
                border: const BorderSide(color: Colors.black, width: 1.25),
                shadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  )
                ],
                child: const Text(
                  'Enter the SWOPSTORE',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                onTap: () => Get.to(() => const PurchaseScreen()),
              ),

              const SizedBox(height: _gapS),

              // BLACK PILL (weight down one level to w400)
              _Pill(
                height: _pillH,
                radius: _pillR,
                fill: Colors.black,
                shadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  )
                ],
                child: const Text(
                  'FAQ and Troubleshooting',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                onTap: () => Get.to(() => const FAQScreen()),
              ),

              const SizedBox(height: _gapL),

              // ACCOUNT INFORMATION CARD (tighter padding & rows, FAQ row removed)
              _BlackCard(
                radius: _cardR,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6), // tighter
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2), // tighter under header

                    _AccountRow(
                      height: _rowH,
                      label: 'Edit Profile',
                      onTap: () => Get.to(() => const UpdateProfileScreen()),
                    ),
                    _AccountRow(
                      height: _rowH,
                      label: 'Send Feedback',
                      onTap: () =>
                          FeedbackModalHelper.showFeedbackModal(context),
                    ),
                    _AccountRow(
                      height: _rowH,
                      label: 'Privacy Policy',
                      onTap: () => Get.to(() => const PrivacyPolicyScreen(
                        url:
                        'https://profile.swopband.com/privacy_policy.html',
                        type: 'Privacy Policy',
                      )),
                    ),
                    _AccountRow(
                      height: _rowH,
                      label: 'Terms and Conditions',
                      onTap: () => Get.to(() => const PrivacyPolicyScreen(
                        url:
                        'https://profile.swopband.com/terms_and_conditions.html',
                        type: 'Term & Condition',
                      )),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _gapL),

              // SIGN OUT PILL
              _Pill(
                height: _pillH,
                radius: _pillR,
                fill: Colors.black,
                shadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  )
                ],
                child: const Text(
                  'Sign Out of your Account',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                onTap: _showSignOutDialog,
              ),

              const SizedBox(height: _gapL),

              // RESET SWOPBAND CARD (paragraph size increased earlier; kept)
              _BlackCard(
                radius: _cardR,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset SWOPBAND',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Resetting SWOPBAND will disconnect the band and your account will be deleted.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16, // increased
                        height: 1.38,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Pill(
                      height: 52,
                      radius: 24,
                      fill: Colors.white,
                      child: const Text(
                        'Reset SWOPBAND',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  // ================== UI helpers ==================

  Future<void> _showSignOutDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        ),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _signOutUser();
            },
            child: const Text('SIGN OUT',
                style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently:',
                style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w400)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Delete all your data',
                      style: TextStyle(
                          fontFamily: 'Outfit', fontWeight: FontWeight.w400)),
                  Text('• Remove your profile',
                      style: TextStyle(
                          fontFamily: 'Outfit', fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('This action cannot be undone.',
                style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAndSignOutUser1();
            },
            child: const Text('DELETE ACCOUNT',
                style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ================== EXISTING LOGIC (unchanged) ==================

  Future<void> _deleteAndSignOutUser() async {
    try {
      final backendUserId =
      await SharedPrefService.getString('backend_user_id');

      if (backendUserId != null && backendUserId.isNotEmpty) {
        final response = await ApiService.delete(
          'https://profile.swopband.com/users/$backendUserId',
        );

        if (response == null ||
            (response.statusCode != 200 && response.statusCode != 204)) {
          SnackbarUtil.showError('Failed to delete account on server.');
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      bool deleted = false;

      if (user != null) {
        try {
          await user.delete();
          deleted = true;
        } catch (e) {
          log("⚠️ Direct deletion failed: $e");
          try {
            if (Platform.isIOS) {
              final appleCredential =
              await SignInWithApple.getAppleIDCredential(
                scopes: [
                  AppleIDAuthorizationScopes.email,
                  AppleIDAuthorizationScopes.fullName
                ],
              );
              final oauthCredential = OAuthProvider("apple.com").credential(
                idToken: appleCredential.identityToken,
              );
              await user.reauthenticateWithCredential(oauthCredential);
              await user.delete();
              deleted = true;
            } else if (Platform.isAndroid) {
              final googleUser = await GoogleSignIn().signIn();
              if (googleUser == null) {
                SnackbarUtil.showError('Google sign-in canceled.');
                return;
              }
              final googleAuth = await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              await user.reauthenticateWithCredential(credential);
              await user.delete();
              deleted = true;
              await GoogleSignIn().disconnect();
            }
          } catch (reauthError) {
            log("❌ Re-auth or deletion failed: $reauthError");
            await user.reload();
            if (FirebaseAuth.instance.currentUser == null) {
              deleted = true;
            } else {
              SnackbarUtil.showError(
                  "Account deletion failed after re-authentication.");
              return;
            }
          }
        }
      }

      if (!deleted) {
        SnackbarUtil.showError("Account deletion failed.");
        return;
      }

      await FirebaseAuth.instance.signOut();
      if (Platform.isAndroid) await GoogleSignIn().signOut();
      await SharedPrefService.clear();

      Get.offAll(() => const WelcomeScreen());
      SnackbarUtil.showSuccess(
          'Account Deleted: Your account has been deleted.');
    } catch (e) {
      log('❌ Error deleting/signing out: $e');
      SnackbarUtil.showError('Failed to delete account.');
    }
  }

  Future<void> _signOutUser() async {
    try {
      try {
        final recentSwoppersController = Get.find<RecentSwoppersController>();
        recentSwoppersController.clearAllDataOnLogout();
      } catch (e) {
        log("⚠️ RecentSwoppersController not found during logout: $e");
      }
      await FirebaseAuth.instance.signOut();
      if (Platform.isAndroid) await GoogleSignIn().signOut();
      await SharedPrefService.clear();
      Get.offAll(() => const WelcomeScreen());
      log("✅ Complete logout successful - all data cleared");
    } catch (e) {
      print('❌ Error signing out: $e');
      SnackbarUtil.showError('Failed to sign out.');
    }
  }

  Future<void> _attemptFirebaseAccountDeletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.delete();
      log('✅ Firebase account deleted successfully');
    } catch (e) {
      log('⚠️ Firebase account deletion failed: $e');
    }
  }

  Future<void> _forceSignOutAndClearData() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (Platform.isAndroid) {
        await GoogleSignIn().signOut();
        await GoogleSignIn().disconnect();
      }
      await SharedPrefService.clear();
      log('✅ All sessions and data cleared');
    } catch (e) {
      log('❌ Error during signout: $e');
    }
  }

  Future<void> _deleteAndSignOutUser1() async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()),
          barrierDismissible: false);

      final backendUserId =
      await SharedPrefService.getString('backend_user_id');
      if (backendUserId != null && backendUserId.isNotEmpty) {
        final response = await ApiService.delete(
          'https://profile.swopband.com/users/$backendUserId',
        );
        if (response == null ||
            (response.statusCode != 200 && response.statusCode != 204)) {
          Get.back();
          SnackbarUtil.showError('Failed to delete account on server.');
          return;
        }
      }

      await _attemptFirebaseAccountDeletion();
      await _forceSignOutAndClearData();

      Get.offAll(() => const WelcomeScreen());
      SnackbarUtil.showSuccess('Account deleted successfully');
    } catch (e) {
      log('❌ Error during account deletion: $e');
      SnackbarUtil.showError('An error occurred during account deletion');
    } finally {
      if (Get.isDialogOpen!) Get.back();
    }
  }
}

// =================== UI widgets ===================

class _Pill extends StatelessWidget {
  final double height;
  final double radius;
  final Color fill;
  final BorderSide? border;
  final List<BoxShadow>? shadow;
  final Widget child;
  final VoidCallback onTap;

  const _Pill({
    required this.height,
    required this.radius,
    required this.fill,
    required this.child,
    required this.onTap,
    this.border,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: border != null ? Border.fromBorderSide(border!) : null,
            boxShadow: shadow,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _BlackCard extends StatelessWidget {
  final double radius;
  final EdgeInsets padding;
  final Widget child;
  const _BlackCard({
    required this.radius,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

// Row WITHOUT left icon (icons removed)
class _AccountRow extends StatelessWidget {
  final double height;
  final String label;
  final VoidCallback onTap;

  const _AccountRow({
    required this.height,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        height: height, // 40
        child: Row(
          children: [
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w400, // lighter per request
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
