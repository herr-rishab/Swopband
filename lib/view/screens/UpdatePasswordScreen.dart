import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_textfield.dart';
import '../translations/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../utils/images/iamges.dart';
import '../utils/app_colors.dart';

class UpdatePasswordScreen extends StatefulWidget {

  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController swopHandleController = TextEditingController();

  final TextEditingController bioController = TextEditingController();
  File? _profileImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              MyImages.background1,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.updatePassword.tr,
                            style: AppTextStyles.large.copyWith(
                              color: MyColors.textWhite, // Dummy secondary color
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          myFieldAdvance(
                              context: context,
                              controller: TextEditingController(),
                              hintText: 'password'.tr,
                              inputType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              showPasswordToggle: true,
                              autofillHints: [AutofillHints.password], fillColor: MyColors.textWhite, textBack: MyColors.textWhite
                          ),
                          const SizedBox(height: 8),
                          myFieldAdvance(
                              context: context,
                              controller: TextEditingController(),
                              hintText: AppStrings.newPassword.tr,
                              inputType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              showPasswordToggle: true,
                              autofillHints: [AutofillHints.password], fillColor: MyColors.textWhite, textBack: MyColors.textWhite
                          ),
                          const SizedBox(height: 8),
                          myFieldAdvance(
                              context: context,
                              controller: TextEditingController(),
                              hintText: AppStrings.confirmNewPassword.tr,
                              inputType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              showPasswordToggle: true,
                              autofillHints: [AutofillHints.password], fillColor: MyColors.textWhite, textBack: MyColors.textWhite
                          ),
                          const SizedBox(height: 15,),

                          CustomButton(
                            buttonColor: Colors.white,
                            textColor: Colors.black,
                            text: AppStrings.changePassword.tr,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}