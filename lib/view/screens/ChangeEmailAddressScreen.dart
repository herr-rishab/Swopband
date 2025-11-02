import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_textfield.dart';
import '../translations/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../utils/images/iamges.dart';
import '../utils/app_colors.dart';

class UpdateEmailScreen extends StatefulWidget {

  const UpdateEmailScreen({super.key});

  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
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
                          AppStrings.updateEmail.tr,
                          style: AppTextStyles.large.copyWith(
                            color: MyColors.textWhite, // Dummy secondary color
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20,),
                        myFieldAdvance(
                            context: context,
                            controller: TextEditingController(),
                            hintText: AppStrings.currentEmailAddress.tr,
                            inputType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next, fillColor: MyColors.textWhite, textBack: MyColors.textWhite
                        ),
                        const SizedBox(height: 8,),
                        myFieldAdvance(
                            context: context,
                            controller: TextEditingController(),
                            hintText: AppStrings.newEmailAddress.tr,
                            inputType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            fillColor: MyColors.textWhite, textBack: MyColors.textWhite
                        ),
                        const SizedBox(height: 8,),
                        myFieldAdvance(
                            context: context,
                            controller: TextEditingController(),
                            hintText: AppStrings.confirmEmailAddress.tr,
                            inputType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next, fillColor: MyColors.textWhite, textBack: MyColors.textWhite
                        ),
                        const SizedBox(height: 15,),

                        CustomButton(
                          buttonColor: Colors.white,
                          textColor: Colors.black,
                          text: AppStrings.changeEmail.tr,
                          onPressed: () {
                            Get.to(()=>const UpdateEmailScreen());
                          },
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
