import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/images/iamges.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';
import '../../services/nfc_background_service.dart';
import 'nfc_test_screen.dart';

class HubScreen extends StatefulWidget {

  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final TextEditingController swopHandleController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final NfcBackgroundService _nfcService = NfcBackgroundService();
  File? _profileImage;
  bool _isNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final isAvailable = await _nfcService.isNfcAvailable;
    setState(() {
      _isNfcAvailable = isAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              MyImages.background6,
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: MyColors.primaryColor.withOpacity(0.1),
                        backgroundImage:const AssetImage('assets/images/profileImage.png'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.question_mark,color: Colors.black,),
                            ),
                            SizedBox(height: 10,),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.language,color: Colors.white),
                            ),
                          ],
                        ),
                      )

                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Toby Reberts",
                    style: AppTextStyles.large.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: MyColors.textBlack,
                    ),),
                  const SizedBox(height: 24),
                  Container(
                    decoration: const BoxDecoration(color: MyColors.textBlack,borderRadius: BorderRadius.all(Radius.circular(20))),
                    height: 30,child:    Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      "janedoe.swop ",
                      style: AppTextStyles.small.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: MyColors.textWhite,
                      ),),
                  ),),
                  const SizedBox(height: 10),
                  Text(
                    "Design Director and CreativePartner at SWOPBAND",
                    style: AppTextStyles.large.copyWith(fontSize: 13,fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  
                  Image.asset("assets/images/groupImage.png",width: double.infinity,),
                  const SizedBox(height: 20),
                  
                  // NFC Status Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.nfc,
                          size: 48,
                          color: _isNfcAvailable 
                              ? (_nfcService.isListening ? Colors.green : Colors.blue)
                              : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isNfcAvailable 
                              ? (_nfcService.isListening ? 'NFC Active' : 'NFC Ready')
                              : 'NFC Not Available',
                          style: AppTextStyles.medium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isNfcAvailable 
                                ? (_nfcService.isListening ? Colors.green : Colors.blue)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isNfcAvailable 
                              ? (Platform.isIOS 
                                  ? 'Tap to scan NFC tag'
                                  : 'Ready to connect automatically')
                              : 'Your device does not support NFC',
                          style: AppTextStyles.small.copyWith(
                            color: MyColors.textDisabledColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Platform-specific buttons
                        if (_isNfcAvailable) ...[
                          if (Platform.isIOS) ...[
                            // iOS: Manual scan button
                            ElevatedButton.icon(
                              onPressed: _nfcService.isSessionActive 
                                  ? null 
                                  : () => _nfcService.startManualNfcSession(),
                              icon: Icon(
                                _nfcService.isSessionActive ? Icons.hourglass_empty : Icons.nfc,
                                color: Colors.white
                              ),
                              label: Text(
                                _nfcService.isSessionActive ? 'Scanning...' : 'Scan NFC Tag',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _nfcService.isSessionActive ? Colors.grey : Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Android: Test button
                            ElevatedButton.icon(
                              onPressed: () => _nfcService.triggerManualNfcCheck(),
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text(
                                'Test NFC',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          // No NFC available
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'NFC Not Supported',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Test Screen Button
                        TextButton.icon(
                          onPressed: () => Get.to(() => const NfcTestScreen()),
                          icon: const Icon(Icons.bug_report, color: Colors.orange),
                          label: const Text(
                            'Debug NFC',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      Platform.isIOS 
                          ? 'Tap "Scan NFC Tag" and hold your phone near an NFC tag to connect'
                          : 'Simply hold your phone near any NFC tag to connect automatically!',
                      style: AppTextStyles.small.copyWith(
                        color: MyColors.textDisabledColor,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}