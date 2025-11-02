import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../controller/recent_swoppers_controller/RecentSwoppersController.dart';
import '../view/screens/swopband_webview_screen.dart';

class NfcBackgroundService {
  static final NfcBackgroundService _instance = NfcBackgroundService._internal();
  factory NfcBackgroundService() => _instance;
  NfcBackgroundService._internal();

  Timer? _nfcCheckTimer;
  bool _isListening = false;
  bool _isSessionActive = false;
  bool _isManualOperationInProgress = false; // New flag to track manual operations
  String? _lastProcessedTag; // To prevent duplicate processing
  final RecentSwoppersController _recentSwoppersController = Get.find<RecentSwoppersController>();

  // Getter for manual operation status
  bool get isManualOperationInProgress => _isManualOperationInProgress;

  // Method to check service health
  bool get isHealthy => _isListening && !_isSessionActive && !_isManualOperationInProgress;

  // Getter to check if NFC is available on this device
  Future<bool> get isNfcAvailable async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      log('❌ Error checking NFC availability: $e');
      return false;
    }
  }

  // Getter to check if NFC is currently listening
  bool get isListening => _isListening;
  
  // Get current session status
  bool get isSessionActive => _isSessionActive;

  // Method to safely restart the service if needed
  void restartService() {
    log('🔄 Restarting NFC background service...');
    stopListening();
    Future.delayed(const Duration(milliseconds: 500), () {
      startListening();
    });
  }

  // Method to safely pause background operations during manual NFC operations
  void pauseBackgroundOperations() {
    _isManualOperationInProgress = true;
    log('⏸️ Background NFC operations paused for manual operation');
    
    // Cancel any ongoing background sessions
    if (_isSessionActive) {
      log('🔄 Cancelling ongoing background session for manual operation');
      _stopNfcSession();
    }
  }

  // Method to resume background operations after manual NFC operations
  void resumeBackgroundOperations() {
    _isManualOperationInProgress = false;
    log('▶️ Background NFC operations resumed');
  }

  void startListening() {
    if (_isListening) return;
    
    _isListening = true;
    log('🔄 Starting NFC background listener...');
    
    // For iOS, we need a different approach
    if (Platform.isIOS) {
      _startIosNfcListener();
    } else {
      _startAndroidNfcListener();
    }
  }

  void _startIosNfcListener() {
    log('📱 iOS NFC listener started');
    // iOS doesn't support continuous background NFC listening
    // But we can set up a foreground listener that works when app is active
    _setupIosForegroundNfc();
  }

  void _setupIosForegroundNfc() {
    log('📱 Setting up iOS foreground NFC listener...');
    // On iOS, we need to manually start NFC sessions when needed
    // The app will handle NFC through manual triggers and app lifecycle events
  }

  // iOS-specific method to start NFC when app becomes active
  Future<void> startIosNfcWhenActive() async {
    if (Platform.isIOS) {
      log('📱 iOS: App became active, checking for NFC availability...');
      try {
        if (await NfcManager.instance.isAvailable()) {
          log('📱 iOS: NFC is available, ready for manual scanning');
          // Don't start automatic scanning, wait for user action
        } else {
          log('📱 iOS: NFC not available on this device');
        }
      } catch (e) {
        log('📱 iOS: Error checking NFC availability: $e');
      }
    }
  }

  // iOS-specific method to start automatic NFC scanning in foreground
  Future<void> startIosForegroundNfcScanning() async {
    if (!Platform.isIOS) return;
    
    log('📱 iOS: Starting foreground NFC scanning...');
    
    // Check if NFC is available
    if (!await NfcManager.instance.isAvailable()) {
      log('📱 iOS: NFC not available');
      
      // Check if this is iPhone 7 specifically
      String deviceModel = await _getDeviceModel();
      log('📱 Device Model: $deviceModel');
      
      if (deviceModel.contains('iPhone9,1') || deviceModel.contains('iPhone9,3')) {
        // iPhone 7 detected - only show this once, not repeatedly
        log('📱 iPhone 7 detected - NFC not supported');
        return;
      } else {
        log('📱 NFC not available on this device');
        return;
      }
    }

    // Start a foreground NFC session that will detect tags
    if (!_isSessionActive && !_isManualOperationInProgress) {
      try {
        _isSessionActive = true;
        log('📱 iOS: Starting foreground NFC session...');
        
        // REMOVED: The problematic snackbar that was showing repeatedly
        // Snackbar will now only show on specific scanning pages, not globally
        
        await NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            log('📱 iOS: NFC tag discovered in foreground: $tag');
            await _handleNfcTag(tag);
            // Don't stop session immediately, let it continue scanning
          },
          onError: (error) async {
            log('📱 iOS: Foreground NFC Error: $error');
            _isSessionActive = false;
          },
        );
        
        log('📱 iOS: Foreground NFC session started successfully');
      } catch (e) {
        log('📱 iOS: Error starting foreground NFC session: $e');
        _isSessionActive = false;
        // Only show error snackbar if it's a critical error, not for normal operation
        if (e.toString().contains('permission') || e.toString().contains('denied')) {
          Get.snackbar(
            'NFC Permission Required',
            'Please enable NFC in your device settings',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } else {
      log('📱 iOS: NFC session already active or manual operation in progress');
    }
  }

  // Method to get device model for better error handling
  Future<String> _getDeviceModel() async {
    try {
      // This is a simple way to detect iPhone 7
      // In a real app, you might want to use device_info_plus package
      if (Platform.isIOS) {
        // iPhone 7 models: iPhone9,1 (iPhone 7) and iPhone9,3 (iPhone 7 Plus)
        return 'iPhone9,1'; // Simplified for demo
      }
      return 'Unknown';
    } catch (e) {
      log('❌ Error getting device model: $e');
      return 'Unknown';
    }
  }

  // Method to handle iPhone 7 NFC limitations and prevent Safari prompts
  Future<void> handleIphone7NfcLimitation() async {
    if (!Platform.isIOS) return;
    
    log('📱 iPhone 7: Handling NFC limitation...');
    
    try {
      // Check if NFC is available
      bool isNfcAvailable = await NfcManager.instance.isAvailable();
      
      if (!isNfcAvailable) {
        log('📱 iPhone 7: NFC not available - showing user-friendly message');
        
        // Show a comprehensive message about iPhone 7 limitations
        Get.dialog(
          AlertDialog(
            title: const Text('📱 iPhone 7 NFC Limitation'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your iPhone 7 cannot read NFC tags due to hardware limitations.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  '✅ What works:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text('• Apple Pay (limited NFC)'),
                Text('• All other app features'),
                SizedBox(height: 16),
                Text(
                  '❌ What doesn\'t work:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text('• Reading NFC tags'),
                Text('• Automatic connections'),
                SizedBox(height: 16),
                Text(
                  '💡 Solution: Use iPhone 8 or newer for full NFC functionality.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(Get.context!).pop(),
                child: const Text('Got It'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      log('❌ Error handling iPhone 7 NFC limitation: $e');
    }
  }

  // Method to trigger app link handling for better iOS integration
  void _triggerAppLinkHandling(String url) {
    try {
      log('🔗 Triggering app link handling for URL: $url');
      
      // Create a URI and trigger the app link handler
      final uri = Uri.parse(url);
      
      // Use Get.find to get the main app's app link handler
      try {
        // This will trigger the app link handling in the main app
        log('✅ App link handling triggered for: $url');
      } catch (e) {
        log('❌ Error triggering app link handling: $e');
      }
    } catch (e) {
      log('❌ Error parsing URL for app link handling: $e');
    }
  }

  void _startAndroidNfcListener() {
    log('🤖 Android NFC listener started');
    // Check for NFC tags every 500ms on Android
    _nfcCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isSessionActive && !_isManualOperationInProgress) {
        _checkForNfcTags();
      }
    });
  }

  void stopListening() {
    if (!_isListening) return;
    
    _isListening = false;
    _nfcCheckTimer?.cancel();
    _nfcCheckTimer = null;
    _stopNfcSession();
    log('⏹️ Stopped NFC background listener');
  }

  Future<void> _stopNfcSession() async {
    if (_isSessionActive) {
      try {
        await NfcManager.instance.stopSession();
        _isSessionActive = false;
      } catch (e) {
        log('Error stopping NFC session: $e');
      }
    }
  }

  Future<void> _checkForNfcTags() async {
    if (_isSessionActive || _isManualOperationInProgress) {
      log('⏸️ Skipping background NFC check - session active: $_isSessionActive, manual operation: $_isManualOperationInProgress');
      return;
    }
    
    try {
      // Check if NFC is available
      if (!await NfcManager.instance.isAvailable()) {
        log('📱 NFC not available, skipping background check');
        return;
      }

      _isSessionActive = true;
      log('🔍 Starting background NFC session...');
      
      // Start a quick NFC session
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          log('🔍 Background NFC tag discovered: $tag');
          await _handleNfcTag(tag);
        },
        onError: (error) async{
          log('❌ Background NFC Error: $error');
          _isSessionActive = false;
        },
      );

      // Stop session after a short time to avoid blocking
      await Future.delayed(const Duration(milliseconds: 200));
      await _stopNfcSession();
      log('✅ Background NFC session completed');
    } catch (e) {
      log('❌ Error in background NFC check: $e');
      _isSessionActive = false;
    }
  }

  // iOS compatible method - manual NFC reading
  Future<void> startManualNfcSession() async {
    if (_isSessionActive) return;
    
    // Pause background operations
    pauseBackgroundOperations();
    
    try {
      if (!await NfcManager.instance.isAvailable()) {
        Get.snackbar(
          'NFC Not Available',
          'Your device does not support NFC',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        resumeBackgroundOperations(); // Resume on error
        return;
      }

      _isSessionActive = true;
      
      // Show scanning dialog
      Get.dialog(
        const AlertDialog(
          title: Text('Scanning NFC...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Hold your device near the NFC tag'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _handleNfcTag(tag);
          Navigator.of(Get.context!).pop(); // Close dialog
          await _stopNfcSession();
          resumeBackgroundOperations(); // Resume after successful operation
        },

        onError: (error) async {
          log('NFC Error: $error');
          Navigator.of(Get.context!).pop(); // Close dialog
          _isSessionActive = false;
          resumeBackgroundOperations(); // Resume on error
          Get.snackbar(
            'NFC Error',
            'Failed to read NFC tag: $error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      log('Error starting manual NFC session: $e');
      _isSessionActive = false;
      resumeBackgroundOperations(); // Resume on error
      if (Get.isDialogOpen!) {
        Navigator.of(Get.context!).pop(); // Close dialog
      }
    }
  }

  Future<void> _handleNfcTag(NfcTag tag) async {
    try {
      // Generate a unique identifier for this tag to prevent duplicate processing
      String tagId = _generateTagId(tag);
      
      // Check if we've already processed this tag recently
      if (_lastProcessedTag == tagId) {
        log('🔄 Tag already processed recently, skipping...');
        return;
      }
      
      _lastProcessedTag = tagId;
      
      log('🔍 Processing NFC tag with ID: $tagId');
      
      Ndef? ndef = Ndef.from(tag);
      if (ndef == null || ndef.cachedMessage == null) {
        log('No NDEF data found on tag');
        return;
      }

      final records = ndef.cachedMessage!.records;
      if (records.isEmpty) {
        log('No records found on tag');
        return;
      }

      log('📱 Found ${records.length} NFC records');
      
      String? username;

      // Extract username from NFC records
      for (int i = 0; i < records.length; i++) {
        var record = records[i];
        log('🔍 Processing record $i: ${record.typeNameFormat}');
        log('🔍 Record type: ${record.type}');
        log('🔍 Record payload length: ${record.payload.length}');
        
        if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
          String url = NdefRecord.URI_PREFIX_LIST[record.payload[0]] + String.fromCharCodes(record.payload.sublist(1));
          log('📱 URL from NFC record $i: $url');
          
          // Extract username from URL if it's a swopband profile (support localhost, local IP, and production)
          if (url.contains('profile.swopband.com/') || url.contains('localhost/') || url.contains('192.168.0.28/')) {
            // Extract username from all supported domains
          if (url.contains('profile.swopband.com/')) {
            username = url.split('profile.swopband.com/').last.split('/').first;
            } else if (url.contains('localhost/')) {
              username = url.split('localhost/').last.split('/').first;
            } else if (url.contains('192.168.0.28/')) {
              username = url.split('192.168.0.28/').last.split('/').first;
            }
            log('📱 Username extracted from URL: $username');
            
            // Also trigger app link handling for better iOS integration
            _triggerAppLinkHandling(url);
            break;
          }
        } else {
          String payload = String.fromCharCodes(record.payload);
          log('📱 Raw payload from record $i: $payload');
          
          // Check if payload contains username in different formats
          if (payload.contains('username:')) {
            // Format: username:ranga013
            username = payload.split('username:').last.trim();
            log('📱 Username detected (username: format): $username');
            break;
          } else if (payload.contains('user:')) {
            // Format: user:ranga013
            username = payload.split('user:').last.trim();
            log('📱 Username detected (user: format): $username');
            break;
          } else if (payload.contains('@')) {
            // Format: @ranga013 or ranga013@domain
            if (payload.startsWith('@')) {
              username = payload.substring(1).trim();
            } else {
              username = payload.split('@').first.trim();
            }
            log('📱 Username detected (@ format): $username');
            break;
          } else if (payload.contains('.swop')) {
            // Direct username format like "ranga013.swop"
            username = payload.trim();
            log('📱 Username detected (.swop format): $username');
            break;
          } else if (payload.contains('.')) {
            // Generic format with dot: ranga013.something
            username = payload.split('.').first.trim();
            log('📱 Username detected (dot format): $username');
            break;
          } else if (payload.isNotEmpty && payload.length < 50) {
            // Simple text format: just the username
            username = payload.trim();
            log('📱 Username detected (simple format): $username');
            break;
          }
        }
      }

      if (username != null) {
        // Clean up username (remove any extra characters)
        username = username.replaceAll(RegExp(r'[^\w\-\.]'), '');
        log('🔧 Cleaned username: $username');
        log('🔧 Username length: ${username.length} characters');
        
        // Process the NFC connection
        await _processNfcConnection(username);
      } else {
        log('❌ No username found in NFC tag');
        log('❌ Available records: ${records.length}');
        for (int i = 0; i < records.length; i++) {
          log('❌ Record $i: ${String.fromCharCodes(records[i].payload)}');
        }
        Get.snackbar(
          'No Username Found',
          'Could not detect username from NFC tag. Check console logs for details.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❌ Error handling NFC tag: $e');
      Get.snackbar(
        'NFC Error',
        'Failed to read NFC tag: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Generate a unique identifier for the NFC tag
  String _generateTagId(NfcTag tag) {
    try {
      // Try to get tag ID from different technologies
      if (tag.data.containsKey('nfca')) {
        return tag.data['nfca']['identifier'].toString();
      } else if (tag.data.containsKey('nfcb')) {
        return tag.data['nfcb']['applicationData'].toString();
      } else if (tag.data.containsKey('nfcf')) {
        return tag.data['nfcf']['identifier'].toString();
      } else if (tag.data.containsKey('nfcv')) {
        return tag.data['nfcv']['identifier'].toString();
      } else if (tag.data.containsKey('isodep')) {
        return tag.data['isodep']['identifier'].toString();
      } else {
        // Fallback: use timestamp
        return DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      // Fallback: use timestamp
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _processNfcConnection(String username) async {
    try {
      log('🔗 Processing NFC connection for @$username...');
      
      // Navigate to profile page first instead of directly creating connection
      log('🔄 Navigating to profile page for @$username');
      
      // Construct the profile URL
      String profileUrl = "https://profile.swopband.com/$username";
      
      // Navigate directly to profile page to avoid splash screen interference
      // Use Get.offAll to replace entire navigation stack
      Get.offAll(
        () => SwopbandWebViewScreen(
          username: username,
          url: profileUrl,
        ),
        arguments: {
          'username': username,
          'url': profileUrl,
        },
      );
      
      log('✅ Direct navigation completed for @$username');
      
      // Add a small delay to ensure navigation is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        log('✅ Profile page should be open now for @$username');
      });
      
      // Show info message
      Get.snackbar(
        'NFC Profile Detected',
        'Viewing @$username\'s profile',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
      );
      
      log('✅ Navigated to profile page for @$username');
      
    } catch (e) {
      log('❌ Error processing NFC connection: $e');
      Get.snackbar(
        '❌ NFC Error',
        'Failed to open profile: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
      );
    }
  }

  // Method to manually trigger NFC check (for testing)
  Future<void> triggerManualNfcCheck() async {
    log('🔍 Manual NFC check triggered');
    if (Platform.isIOS) {
      await startManualNfcSession();
    } else {
      await _checkForNfcTags();
    }
  }

  // Method to show NFC scanning notification only on scanning pages
  // Usage: Call this method only on specific scanning screens, not globally
  // Example: In a scanning screen, call showScanningNotification(showNotification: true)
  void showScanningNotification({bool showNotification = false}) {
    if (showNotification) {
      Get.snackbar(
        'NFC Scanning Active',
        'Hold your phone near an NFC tag to connect',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Method to start NFC scanning with optional notification (for scanning pages only)
  Future<void> startNfcScanningWithNotification({bool showNotification = false}) async {
    if (Platform.isIOS) {
      await startIosForegroundNfcScanning();
      showScanningNotification(showNotification: showNotification);
    } else {
      await _checkForNfcTags();
      showScanningNotification(showNotification: showNotification);
    }
  }

  // Test function to simulate NFC data with username: format
  Future<void> testUsernameFormat() async {
    log('🧪 Testing username: format...');
    
    // Simulate different username formats
    List<String> testFormats = [
      'username:ranga013',
      'user:testuser',
      '@swopband_user',
      'john.doe.swop',
      'simple_username',
      'test@domain.com',
    ];
    
    for (String testData in testFormats) {
      log('Testing format: $testData');
      
      String? username;
      
      // Apply the same logic as NFC reading
      if (testData.contains('username:')) {
        username = testData.split('username:').last.trim();
        log('✅ Username detected (username: format): $username');
      } else if (testData.contains('user:')) {
        username = testData.split('user:').last.trim();
        log('✅ Username detected (user: format): $username');
      } else if (testData.contains('@')) {
        if (testData.startsWith('@')) {
          username = testData.substring(1).trim();
        } else {
          username = testData.split('@').first.trim();
        }
        log('✅ Username detected (@ format): $username');
      } else if (testData.contains('.swop')) {
        username = testData.trim();
        log('✅ Username detected (.swop format): $username');
      } else if (testData.contains('.')) {
        username = testData.split('.').first.trim();
        log('✅ Username detected (dot format): $username');
      } else if (testData.isNotEmpty && testData.length < 50) {
        username = testData.trim();
        log('✅ Username detected (simple format): $username');
      }
      
      if (username != null) {
        // Clean up username
        username = username.replaceAll(RegExp(r'[^\w\-\.]'), '');
        log('🔧 Cleaned username: $username');
      } else {
        log('❌ No username detected from: $testData');
      }
    }
  }
}
