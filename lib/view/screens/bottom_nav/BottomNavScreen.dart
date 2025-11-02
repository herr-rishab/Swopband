import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/controller/nav_controller/NavController.dart';
import '../../utils/images/iamges.dart';
import '../FeedbackScreen.dart';
import '../EditLinksScreen.dart';
import '../RecentSwoppersScreen.dart';
import '../SettingScreen.dart';
import '../swopband_webview_screen.dart';

class BottomNavScreen extends StatelessWidget {
  BottomNavScreen({super.key});

  final NavController navController = Get.put(NavController());

  final List<Widget> screens = [
    const EditLinksScreen(),
    const RecentSwoppersScreen(),
    // HubScreen(),
    const SwopbandWebViewScreen(url: '',),
    Container(), // Placeholder for feedback - will be handled by navigation
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          Obx(() => screens[navController.selectedIndex.value]),
          
          // Floating bottom navigation bar with gradient background
          Positioned(
            left: MediaQuery.of(context).size.width * 0.01, // 5% of screen width
            right: MediaQuery.of(context).size.width * 0.01, // 5% of screen width
            bottom: MediaQuery.of(context).padding.bottom , // Safe area + 10px
            child: Container(
              height: MediaQuery.of(context).size.height * 0.08, // 8% of screen height
              constraints: const BoxConstraints(
                minHeight: 60,
                maxHeight: 80,
              ),
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02), // 2% of screen width
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, MyImages.bottomImg5, 'Links',context),
                    _buildNavItem(1, MyImages.bottomImg1, 'Profile',context),
                    _buildNavItem(2, MyImages.bottomImg4, 'Groups',context),
                    _buildNavItem(3, MyImages.bottomImg3, 'Feedback',context),
                    _buildNavItem(4, MyImages.bottomImg2, 'Settings',context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String image, String label,BuildContext context) {
    return Obx(() {
      final isSelected = navController.selectedIndex.value == index;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Show labels only on larger screens
      final shouldShowLabels = screenWidth > 400 && screenHeight > 600;
      
      return GestureDetector(
        onTap: () {
          if (index == 3) { // Feedback tab

            showFeedbackPopup(context);

          } else {
            navController.changeIndex(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.015, // 1.5% of screen width
            vertical: screenHeight * 0.01, // 1% of screen height
          ),
          constraints: BoxConstraints(
            minWidth: screenWidth * 0.12, // 12% of screen width
            maxWidth: screenWidth * 0.18, // 18% of screen width
          ),
          // decoration: BoxDecoration(
          //   color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          //   borderRadius: BorderRadius.circular(15),
          // ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                height: isSelected?28:25,
                width: isSelected?28:25,
                image,

                color: isSelected ? Colors.white : Colors.grey,
              ),
              if (isSelected && shouldShowLabels) ...[
                SizedBox(height: screenHeight * 0.005), // 0.5% of screen height
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: "Outfit",
                      color: Colors.white,
                      fontSize: screenWidth * 0.025, // 2.5% of screen width
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
  void showFeedbackPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return const Stack(
          children: [
            // Align bottom with padding = nav bar height
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 60), // 👈 nav bar ki height
                child: FeedbackPopup(),
              ),
            ),
          ],
        );
      },
    );
  }

}