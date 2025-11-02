import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/view/screens/welcome_screen.dart';
import 'package:swopband/view/screens/bottom_nav/BottomNavScreen.dart';
import '../../../controller/user_controller/UserController.dart';
import '../../utils/id_utils.dart';
import '../../utils/images/iamges.dart';
import '../../utils/shared_pref/SharedPrefHelper.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  UserController userController = Get.put(UserController());
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
   /* Timer(Duration(seconds: 2), () {
      Get.to(()=>NfcTestScreen());
    },);*/


  }

/*  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(Duration(seconds: 3)); // Optional splash delay

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final firebaseId = await SharedPrefService.getString('firebase_id');
    final backendUserId = await SharedPrefService.getString('backend_user_id');
    userController.fetchUserByFirebaseId(firebaseId!).then((value) {
      log("firebaseUser: splash $firebaseUser");
      log("firebaseId splash : $firebaseId");
      log("backendUserId splash : $backendUserId");

      if (firebaseUser != null && firebaseId != null && firebaseId.isNotEmpty) {
        if (backendUserId != null && backendUserId.isNotEmpty) {
          // ✅ Case 1: Firebase and Backend ID exist
          Get.off(() => BottomNavScreen());

        } else {
          // ✅ Case 2: Firebase exists but backend ID is null/empty
          Get.off(() => WelcomeScreen());
        }
      } else {
        // ✅ Case 3: Firebase ID and backend ID both are null/missing
        Get.off(() => WelcomeScreen());
      }
    },);

  }*/
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3)); // Optional splash delay

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final firebaseId = await SharedPrefService.getString('firebase_id');
    final backendUserId = await SharedPrefService.getString('backend_user_id');

    log("firebaseUser: splash $firebaseUser");
    log("firebaseId splash : $firebaseId");
    log("backendUserId splash : $backendUserId");

    if (firebaseUser != null && firebaseId != null && firebaseId.isNotEmpty) {
      final userData = await userController.fetchUserByFirebaseId(firebaseId);

      final userId = normalizeBackendUserId(userData?['id']);

      if (userData == null || userId == null || userId.isEmpty) {
        // ❌ API did not return a valid user — go to WelcomeScreen
        Get.off(() => const WelcomeScreen());
      } else if (backendUserId != null && backendUserId.isNotEmpty) {
        // ✅ Firebase and backend user ID exist — go to home
        Get.off(() => BottomNavScreen());
      } else {
        // ✅ Firebase exists, but backend user ID missing — go to Welcome
        Get.off(() => const WelcomeScreen());
      }
    } else {
      // ❌ Firebase user or ID is null — go to WelcomeScreen
      Get.off(() => const WelcomeScreen());
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Dummy background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    MyImages.nameLogo,
                    height: 50
                    ,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
