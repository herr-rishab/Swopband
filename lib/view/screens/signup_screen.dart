import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/controller/user_controller/UserController.dart';
import 'package:swopband/view/screens/bottom_nav/BottomNavScreen.dart';
import 'package:swopband/view/utils/shared_pref/SharedPrefHelper.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import 'package:swopband/view/widgets/custom_textfield.dart';

import '../translations/app_strings.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/images/iamges.dart';
import 'create_profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sureNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  Country _selectedCountry = Country.parse('GB');
  bool _isSubmitting = false;
  bool _isSignUp = true;
  int? _selectedAge;
  String? _selectedGender;

  @override
  void dispose() {
    nameController.dispose();
    sureNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _isSignUp
        ? AppStrings.personalDetails.tr
        : 'Sign in to your account';
    final helperText = _isSignUp
        ? 'Create your login details to get started.'
        : 'Enter your email and password to continue.';

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(MyImages.nameLogo, height: 40),
                  const SizedBox(height: 24),
                  Text(
                    heading,
                    style: AppTextStyles.large.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MyColors.textBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    helperText,
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: MyColors.textBlack.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_isSignUp) ...[
                    _buildNameFields(),
                    const SizedBox(height: 16),
                    _buildAgeGenderField(),
                    const SizedBox(height: 16),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                  ],
                  myFieldAdvance(
                    autofillHints: const [AutofillHints.email],
                    context: context,
                    controller: emailController,
                    hintText: AppStrings.email.tr,
                    inputType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    fillColor: MyColors.textWhite,
                    textBack: MyColors.textWhite,
                  ),
                  const SizedBox(height: 16),
                  myFieldAdvance(
                    context: context,
                    controller: passwordController,
                    hintText: AppStrings.password.tr,
                    inputType: TextInputType.text,
                    textInputAction:
                        _isSignUp ? TextInputAction.next : TextInputAction.done,
                    showPasswordToggle: true,
                    autofillHints: const [AutofillHints.password],
                    fillColor: MyColors.textWhite,
                    textBack: MyColors.textWhite,
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    myFieldAdvance(
                      context: context,
                      controller: confirmPasswordController,
                      hintText: AppStrings.confirmPassword.tr,
                      inputType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      showPasswordToggle: true,
                      fillColor: MyColors.textWhite,
                      textBack: MyColors.textWhite,
                    ),
                  ],
                  const SizedBox(height: 24),
                  CustomButton(
                    text: _isSignUp
                        ? AppStrings.signUp.tr
                        : AppStrings.signIn.tr,
                    onPressed: _submit,
                    isLoading: _isSubmitting,
                    textStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _toggleAuthMode,
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.medium.copyWith(
                          color: MyColors.textBlack,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: _isSignUp
                                ? 'Already have an account? '
                                : "New to Swopband? ",
                          ),
                          TextSpan(
                            text:
                                _isSignUp ? AppStrings.signIn.tr : AppStrings.signUp.tr,
                            style: AppTextStyles.medium.copyWith(
                              color: MyColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: myFieldAdvance(
            autofillHints: const [AutofillHints.givenName],
            context: context,
            controller: nameController,
            hintText: AppStrings.firstName.tr,
            inputType: TextInputType.name,
            textInputAction: TextInputAction.next,
            fillColor: MyColors.textWhite,
            textBack: MyColors.textWhite,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: myFieldAdvance(
            autofillHints: const [AutofillHints.familyName],
            context: context,
            controller: sureNameController,
            hintText: AppStrings.lastName.tr,
            inputType: TextInputType.name,
            textInputAction: TextInputAction.next,
            fillColor: MyColors.textWhite,
            textBack: MyColors.textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
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
              height: 56,
              decoration: BoxDecoration(
                color: MyColors.textWhite,
                border: Border.all(
                  color: Colors.black,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Text(
                    _selectedCountry.flagEmoji,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${_selectedCountry.phoneCode}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Outfit',
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
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
              color: MyColors.textBlack,
            ),
            decoration: const InputDecoration(
              hintText: 'Mobile Number',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
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
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyColors.textBlack,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeGenderField() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: DropdownButtonFormField<int>(
              value: _selectedAge,
              decoration: InputDecoration(
                label: Text(
                  AppStrings.age.tr,
                  style: TextStyle(
                    backgroundColor: MyColors.textWhite,
                    color: MyColors.textBlack.withOpacity(0.8),
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                contentPadding: const EdgeInsets.only(top: 3, left: 20),
                filled: true,
                fillColor: MyColors.textWhite,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.2),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MyColors.textBlack,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: MyColors.textBlack,
              ),
              items: List.generate(83, (index) => index + 18)
                  .map(
                    (age) => DropdownMenuItem<int>(
                      value: age,
                      child: Text(
                        age.toString(),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: MyColors.textBlack,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAge = value;
                });
              },
              hint: Text(
                AppStrings.selectAge.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                label: Text(
                  AppStrings.gender.tr,
                  style: TextStyle(
                    backgroundColor: MyColors.textWhite,
                    color: MyColors.textBlack.withOpacity(0.8),
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                contentPadding: const EdgeInsets.only(top: 3, left: 20),
                filled: true,
                fillColor: MyColors.textWhite,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.2),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MyColors.textBlack,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: MyColors.textBlack,
              ),
              items: [
                AppStrings.male.tr,
                AppStrings.female.tr,
                AppStrings.other.tr,
              ]
                  .map(
                    (gender) => DropdownMenuItem<String>(
                      value: gender,
                      child: Text(
                        gender,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: MyColors.textBlack,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              hint: Text(
                AppStrings.selectGender.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool isValid = _isSignUp ? _validateSignUp() : _validateSignIn();
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isSignUp) {
        await _performSignup();
      } else {
        await _performSignin();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _validateSignUp() {
    final firstName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    if (firstName.isEmpty) {
      SnackbarUtil.showError('Please enter your first name');
      return false;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      SnackbarUtil.showError('Please enter a valid email address');
      return false;
    }
    if (password.isEmpty || password.length < 6) {
      SnackbarUtil.showError('Password must be at least 6 characters long');
      return false;
    }
    if (password != confirmPassword) {
      SnackbarUtil.showError('Passwords do not match');
      return false;
    }
    if (phone.isEmpty || phone.length < 7) {
      SnackbarUtil.showError('Please enter a valid mobile number');
      return false;
    }
    return true;
  }

  bool _validateSignIn() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      SnackbarUtil.showError('Please enter a valid email address');
      return false;
    }
    if (password.isEmpty) {
      SnackbarUtil.showError('Please enter your password');
      return false;
    }
    return true;
  }

  Future<void> _performSignup() async {
    final firstName = nameController.text.trim();
    final lastName = sureNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final fullName =
        [firstName, lastName].where((value) => value.isNotEmpty).join(' ').trim();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        if (fullName.isNotEmpty && (user.displayName ?? '').trim() != fullName) {
          await user.updateDisplayName(fullName);
        }
        await _handleAuthenticatedUser(
          user,
          email: email,
          fullName: fullName,
        );
      } else {
        SnackbarUtil.showError(
            'Unable to complete sign up. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        SnackbarUtil.showError(
            'An account with this email already exists. Please sign in.');
        if (mounted) {
          setState(() {
            _isSignUp = false;
          });
        }
      } else {
        SnackbarUtil.showError(
            e.message ?? 'Failed to sign up. Please try again.');
      }
    } catch (_) {
      SnackbarUtil.showError('Failed to sign up. Please try again.');
    }
  }

  Future<void> _performSignin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        await _handleAuthenticatedUser(
          user,
          email: email,
          fullName: user.displayName,
        );
      } else {
        SnackbarUtil.showError('Unable to sign in. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for this email. Please sign up first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        default:
          message = e.message ?? 'Failed to sign in. Please try again.';
      }
      SnackbarUtil.showError(message);
    } catch (_) {
      SnackbarUtil.showError('Failed to sign in. Please try again.');
    }
  }

  Future<void> _handleAuthenticatedUser(
    User user, {
    String? email,
    String? fullName,
  }) async {
    await SharedPrefService.saveString('firebase_id', user.uid);
    final controller = _resolveUserController();
    final existingUser = await controller.fetchUserByFirebaseId(user.uid);
    if (existingUser != null) {
      Get.offAll(() => BottomNavScreen());
      return;
    }

    final trimmedName = (fullName ?? '').trim();
    final resolvedName =
        trimmedName.isNotEmpty ? trimmedName : (user.displayName ?? '').trim();
    final resolvedEmail = (email ?? user.email ?? '').trim();

    Get.to(
      () => CreateProfileScreen(
        email: resolvedEmail.isNotEmpty ? resolvedEmail : null,
        name: resolvedName.isNotEmpty ? resolvedName : null,
      ),
    );
  }

  UserController _resolveUserController() {
    if (Get.isRegistered<UserController>()) {
      return Get.find<UserController>();
    }
    return Get.put(UserController());
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      if (_isSignUp) {
        confirmPasswordController.clear();
      }
    });
  }
}
