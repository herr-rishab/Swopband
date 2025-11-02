import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/view/screens/splash_screen/SplashScreen.dart';
import 'package:swopband/view/screens/nfc_test_screen.dart';
import 'package:swopband/view/screens/swopband_webview_screen.dart';
import 'package:swopband/view/translations/app_strings.dart';
import 'package:swopband/view/utils/app_text_styles.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:swopband/controller/recent_swoppers_controller/RecentSwoppersController.dart';
import 'package:swopband/services/nfc_background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  String? initialLink;
  try {
    final appLinks = AppLinks();
    final initialUri = await appLinks.getInitialLink();
    initialLink = initialUri?.toString();
    print('getInitialLink: $initialLink');
  } catch (e) {
    print('Error getting initial app link: $e');
  }

  runApp(MyApp(initialNfcUrl: initialLink));

}


class MyApp extends StatefulWidget {
  final String? initialNfcUrl;
  const MyApp({super.key, this.initialNfcUrl});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<Uri>? _appLinksSubscription;
  final RecentSwoppersController recentSwoppersController = Get.put(RecentSwoppersController());
  final NfcBackgroundService _nfcService = NfcBackgroundService();
  final AppLinks _appLinks = AppLinks();
  final bool _hasProcessedInitialLink = false;
  bool _isNavigatingToProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    _initializeAppLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App became active - start iOS NFC scanning
      if (Platform.isIOS) {
        log('📱 iOS: App resumed, starting NFC scanning...');
        Future.delayed(const Duration(milliseconds: 500), () {
          _nfcService.startIosForegroundNfcScanning();
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background - stop NFC scanning
      if (Platform.isIOS) {
        log('📱 iOS: App paused, stopping NFC scanning...');
        _nfcService.stopListening();
      }
    } else if (state == AppLifecycleState.inactive) {
      // App is inactive - pause NFC scanning
      if (Platform.isIOS) {
        log('📱 iOS: App inactive, pausing NFC scanning...');
        _nfcService.stopListening();
      }
    }
  }

  void _initializeApp() {
    // Start NFC background service after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _nfcService.startListening();
      
      // For iPhone 13, also start foreground NFC scanning
      if (Platform.isIOS) {
        log('📱 iOS: Starting initial NFC scanning for iPhone 13...');
        Future.delayed(const Duration(seconds: 3), () {
          _nfcService.startIosForegroundNfcScanning();
        });
      }
    });
  }

  void _initializeAppLinks() {
    // Handle app links when app is already running
    _appLinksSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        log('📱 iOS: App link received: $uri');
        _handleAppLink(uri);
      }
    }, onError: (err) {
      log('❌ App links error: $err');
    });

    // Also check for initial link when app starts
    _checkInitialAppLink();
  }

  Future<void> _checkInitialAppLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        log('📱 iOS: Initial app link found: $initialUri');
        // Don't automatically process initial link to prevent profile page opening on restart
        log('📱 Skipping automatic initial link processing to prevent restart issues');
        log('📱 App will start normally to SplashScreen instead of opening profile page');
      }
    } catch (e) {
      log('❌ Error checking initial app link: $e');
    }
  }

  void _handleAppLink(Uri uri) {
    log('📱 iOS: Processing app link: $uri');
    
    // Support localhost, local IP, and production domain
    if (uri.host == 'profile.swopband.com' || 
        uri.host == 'localhost' || 
        uri.host == '192.168.0.28') {
      // Extract username from URL and show profile page first
      final username = _extractUsernameFromUri(uri);
      if (username != null) {
        log('✅ Username extracted from NFC URL: $username');
        log('🔄 Navigating to profile page for username: $username');
        
        // Navigate to profile page instead of directly creating connection
        _navigateToProfilePage(username, uri.toString());
        
      } else {
        log('❌ Could not extract username from URI: $uri');
        Get.snackbar(
          'Invalid NFC Data',
          'Could not read username from NFC tag',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } else {
      log('⚠️ App link not from supported domain: $uri');
      log('⚠️ Supported domains: profile.swopband.com, localhost, 192.168.0.28');
    }
  }

  String? _extractUsernameFromUri(Uri uri) {
    try {
      // Support localhost, local IP, and production domains
      if ((uri.host == 'profile.swopband.com' || 
           uri.host == 'localhost' || 
           uri.host == '192.168.0.28') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    } catch (e) {
      print('Error extracting username from URI: $e');
    }
    return null;
  }



  void _navigateToProfilePage(String username, String url) {
    if (_isNavigatingToProfile) {
      log('⚠️ Already navigating to profile page, skipping duplicate navigation');
      return;
    }
    
    _isNavigatingToProfile = true;
    log('🔄 Navigating to profile page for @$username');
    log('🔄 Profile URL: $url');
    
    // Add a small delay to ensure proper navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      // Navigate to SwopbandWebViewScreen with proper parameters
      Get.to(
        () => SwopbandWebViewScreen(
          username: username,
          url: url,
        ),
        arguments: {
          'username': username,
          'url': url,
        },
      );
      
      log('✅ Navigation command sent for @$username');
      
      // Reset flag after navigation
      Future.delayed(const Duration(seconds: 2), () {
        _isNavigatingToProfile = false;
      });
    });
    
    // Show info message
    Get.snackbar(
      'NFC Profile Detected',
      'Viewing @$username\'s profile',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _navigateToProfilePageDirectly(String username, String url) {
    if (_isNavigatingToProfile) {
      log('⚠️ Already navigating to profile page, skipping duplicate direct navigation');
      return;
    }
    
    _isNavigatingToProfile = true;
    log('🔄 Navigating directly to profile page for @$username');
    log('🔄 Profile URL: $url');
    
    // Navigate directly without delay to avoid splash screen interference
    Get.offAll(
      () => SwopbandWebViewScreen(
        username: username,
        url: url,
      ),
      arguments: {
        'username': username,
        'url': url,
      },
    );
    
    log('✅ Direct navigation completed for @$username');
    
    // Reset flag after navigation
    Future.delayed(const Duration(seconds: 2), () {
      _isNavigatingToProfile = false;
    });
    
    // Show info message
    Get.snackbar(
      'NFC Profile Detected',
      'Viewing @$username\'s profile',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appLinksSubscription?.cancel();
    _nfcService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Showpband NFC',
      translations: AppStrings(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        fontFamily: AppTextStyles.fontFamily,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(), // Always start with SplashScreen, never auto-open profile page
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/nfc-test', page: () => const NfcTestScreen()),
        // GetPage(name: '/webview', page: () => SwopbandWebViewScreen(url: '')),
      ],
    );
  }
}