import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import '../utils/app_text_styles.dart';
import '../utils/images/iamges.dart';
import '../utils/app_colors.dart';
import 'RingNotConnectScreen.dart';

class ConnectionSuccessScreen extends StatefulWidget {
  const ConnectionSuccessScreen({super.key});

  @override
  State<ConnectionSuccessScreen> createState() => _ConnectionSuccessScreenState();
}

class _ConnectionSuccessScreenState extends State<ConnectionSuccessScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      bottomNavigationBar:  Container(
        color: const Color(0xFFfe2f00),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomButton(
            buttonColor: MyColors.textBlack,
            textColor: MyColors.textWhite,
            text: "Okay",
            onPressed: () {
              Get.to(()=>const RingNotConnectedScreen());
            },
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(MyImages.background2, fit: BoxFit.cover),
          ),
          Positioned(
            top: MediaQuery.of(context).size.width/2, // Half outside the container
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    MyImages.ringImage,
                    height: 130,
                  ),
                  Text(
                    "Connection Successful!",
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 18,
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