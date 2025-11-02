import 'dart:io';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import '../utils/app_text_styles.dart';
import '../utils/images/iamges.dart';
import '../utils/app_colors.dart';

class UpdatePhoneNumberScreen extends StatefulWidget {
  const UpdatePhoneNumberScreen({super.key});

  @override
  State<UpdatePhoneNumberScreen> createState() =>
      _UpdatePhoneNumberScreenState();
}

class _UpdatePhoneNumberScreenState extends State<UpdatePhoneNumberScreen> {
  final TextEditingController swopHandleController = TextEditingController();
  final TextEditingController currentPhoneController = TextEditingController();
  final TextEditingController newPhoneController = TextEditingController();
  final TextEditingController confirmPhoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  File? _profileImage;

  // Country variables
  Country _currentPhoneCountry = Country.parse('GB');
  Country _newPhoneCountry = Country.parse('GB');
  Country _confirmPhoneCountry = Country.parse('GB');

  // Helper method to create phone field with country picker
  Widget _buildPhoneField({
    required TextEditingController controller,
    required String hintText,
    required Country selectedCountry,
    required Function(Country) onCountryChanged,
  }) {
    return Row(
      children: [
        // Country code field with flag
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                onSelect: onCountryChanged,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Text(
                      selectedCountry.flagEmoji,
                      style:
                          const TextStyle(fontSize: 20, fontFamily: "Outfit"),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${selectedCountry.phoneCode}',
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
            controller: controller,
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
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

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
                        "Update Phone Number",
                        style: AppTextStyles.large.copyWith(
                          color: MyColors.textWhite, // Dummy secondary color
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildPhoneField(
                        controller: currentPhoneController,
                        hintText: 'Current Phone Number',
                        selectedCountry: _currentPhoneCountry,
                        onCountryChanged: (country) {
                          setState(() {
                            _currentPhoneCountry = country;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      _buildPhoneField(
                        controller: newPhoneController,
                        hintText: 'New Phone Number',
                        selectedCountry: _newPhoneCountry,
                        onCountryChanged: (country) {
                          setState(() {
                            _newPhoneCountry = country;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      _buildPhoneField(
                        controller: confirmPhoneController,
                        hintText: 'Confirm Phone Number',
                        selectedCountry: _confirmPhoneCountry,
                        onCountryChanged: (country) {
                          setState(() {
                            _confirmPhoneCountry = country;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      CustomButton(
                        buttonColor: Colors.white,
                        textColor: Colors.black,
                        text: "Change Phone Number",
                        onPressed: () {},
                      ),
                    ],
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
