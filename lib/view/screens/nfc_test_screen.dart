import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../../services/nfc_background_service.dart';
import '../../controller/recent_swoppers_controller/RecentSwoppersController.dart';

class NfcTestScreen extends StatefulWidget {
  const NfcTestScreen({super.key});

  @override
  State<NfcTestScreen> createState() => _NfcTestScreenState();
}

class _NfcTestScreenState extends State<NfcTestScreen> {
  final NfcBackgroundService _nfcService = NfcBackgroundService();
  final RecentSwoppersController _recentSwoppersController = Get.find<RecentSwoppersController>();
  final TextEditingController _testUsernameController = TextEditingController();
  bool _isNfcAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _checkNfcStatus();
  }

  Future<void> _checkNfcStatus() async {
    final isAvailable = await _nfcService.isNfcAvailable;
    setState(() {
      _isNfcAvailable = isAvailable;
      _isListening = _nfcService.isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        title: const Text('NFC Test Screen'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NFC Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isNfcAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isNfcAvailable ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.nfc,
                          color: _isNfcAvailable ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'NFC Status',
                          style: AppTextStyles.large.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isNfcAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isNfcAvailable ? 'NFC is available on this device' : 'NFC is not available on this device',
                      style: AppTextStyles.medium.copyWith(
                        color: _isNfcAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isListening ? 'NFC listener is active' : 'NFC listener is inactive',
                      style: AppTextStyles.small.copyWith(
                        color: _isListening ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Test Username Connection
              Text(
                'Test Username Connection',
                style: AppTextStyles.large.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MyColors.textBlack,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _testUsernameController,
                  decoration: InputDecoration(
                    hintText: 'Enter username to test (e.g., ranga013)',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    suffixIcon: IconButton(
                      onPressed: _testUsernameConnection,
                      icon: const Icon(Icons.send, color: Colors.blue),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick Test Buttons
              Text(
                'Quick Test Connections',
                style: AppTextStyles.large.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MyColors.textBlack,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _testUsernameConnectionWithUsername('ranga013'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Test ranga013'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _testUsernameConnectionWithUsername('testuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Test testuser'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Test Buttons
              Text(
                'Test Functions',
                style: AppTextStyles.large.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MyColors.textBlack,
                ),
              ),
              const SizedBox(height: 15),

              // Manual NFC Test Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isNfcAvailable ? _testManualNfc : null,
                  icon: const Icon(Icons.nfc, color: Colors.white),
                  label: const Text('Test Manual NFC Reading'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Test Username Format Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testUsernameFormats,
                  icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
                  label: const Text('Test Username Formats'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Test API Endpoints Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testApiEndpoints,
                  icon: const Icon(Icons.api, color: Colors.white),
                  label: const Text('Test API Endpoints'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Refresh Connections Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _refreshConnections,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Refresh Connections'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Toggle Mock Data Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleMockData,
                  icon: Icon(
                    _recentSwoppersController.useMockData.value 
                        ? Icons.visibility_off 
                        : Icons.visibility,
                    color: Colors.white
                  ),
                  label: Text(_recentSwoppersController.useMockData.value 
                      ? 'Disable Mock Data' 
                      : 'Enable Mock Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 30),

              // Connection Stats
              Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Statistics',
                      style: AppTextStyles.medium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Connections: ${_recentSwoppersController.connectionCount}',
                      style: AppTextStyles.medium.copyWith(color: MyColors.textBlack),
                    ),
                    Text(
                      'Mock Data: ${_recentSwoppersController.useMockData.value ? "Enabled" : "Disabled"}',
                      style: AppTextStyles.medium.copyWith(color: MyColors.textBlack),
                    ),
                    Text(
                      'Loading: ${_recentSwoppersController.fetchRecentSwoppersLoader.value ? "Yes" : "No"}',
                      style: AppTextStyles.medium.copyWith(color: MyColors.textBlack),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testUsernameConnection() async {
    final username = _testUsernameController.text.trim();
    if (username.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a username',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing connection...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final success = await _recentSwoppersController.createConnection(username);
      
      Get.back(); // Close loading dialog

      if (success) {
        Get.snackbar(
          'Success',
          'Connection test successful with @$username',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _testUsernameController.clear();
      } else {
        Get.snackbar(
          'Failed',
          'Connection test failed with @$username',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Test failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _testUsernameConnectionWithUsername(String username) async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing connection...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final success = await _recentSwoppersController.createConnection(username);
      
      Get.back(); // Close loading dialog

      if (success) {
        Get.snackbar(
          'Success',
          'Connection test successful with @$username',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Failed',
          'Connection test failed with @$username',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Test failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _testManualNfc() async {
    try {
      await _nfcService.startManualNfcSession();
    } catch (e) {
      Get.snackbar(
        'NFC Error',
        'Failed to start NFC session: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _testUsernameFormats() {
    _nfcService.testUsernameFormat();
    Get.snackbar(
      'Test Started',
      'Check console logs for username format test results',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> _testApiEndpoints() async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing API endpoints...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      await _recentSwoppersController.testApiEndpoints();
      Get.back(); // Close loading dialog
      Get.snackbar(
        'API Test Complete',
        'API endpoint tests completed. Check console logs for details.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'API Test Error',
        'API endpoint tests failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _refreshConnections() async {
    try {
      await _recentSwoppersController.refreshConnections();
      Get.snackbar(
        'Refreshed',
        'Connections refreshed successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh connections: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _toggleMockData() {
    _recentSwoppersController.toggleMockData();
    Get.snackbar(
      'Mock Data Toggled',
      _recentSwoppersController.useMockData.value 
          ? 'Mock data is now enabled' 
          : 'Mock data is now disabled',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }
}
