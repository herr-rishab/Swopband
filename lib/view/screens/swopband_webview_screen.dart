import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_snackbar.dart';
import '../../controller/recent_swoppers_controller/RecentSwoppersController.dart';
import '../../controller/nav_controller/NavController.dart';
import 'bottom_nav/BottomNavScreen.dart';

class SwopbandWebViewScreen extends StatefulWidget {
  final String? username;
  final String url;

  const SwopbandWebViewScreen({super.key, this.username, required this.url});

  @override
  State<SwopbandWebViewScreen> createState() => _SwopbandWebViewScreenState();
}

class _SwopbandWebViewScreenState extends State<SwopbandWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  final RecentSwoppersController _recentSwoppersController =
      Get.find<RecentSwoppersController>();

  @override
  void initState() {
    super.initState();
    log('🔄 SwopbandWebViewScreen initState called for @${widget.username}');
    String finalUrl;
    if (widget.url.isNotEmpty) {
      finalUrl = widget.url;
    } else {
      final username = widget.username ?? AppConst.USER_NAME;
      finalUrl = "https://profile.swopband.com/$username";
    }

    log("Loading profile: $finalUrl");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // you can log progress here if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });

            // Force hide loader after 3 seconds even if page not fully loaded
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            });
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle phone and email URLs
            if (_handlePhoneOrEmailUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));

    // Automatically create connection when profile page opens
    if (widget.username != null) {
      log('🔄 Starting auto-connection for @${widget.username}');
      _autoConnectWithUser();
    }
  }

  @override
  void dispose() {
    log('🔄 SwopbandWebViewScreen dispose called for @${widget.username}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: widget.username != null
          ? AppBar(
              backgroundColor: MyColors.backgroundColor,
              elevation: 0,
              title: Text(
                '${widget.username}\'s Profile',
                style: AppTextStyles.large.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MyColors.textBlack,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: MyColors.textBlack),
                onPressed: () => _goToRecentSwoppers(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: MyColors.textBlack),
                  onPressed: () {
                    _controller.reload();
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: MyColors.textBlack,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.username != null
                          ? 'Loading ${widget.username}\'s Profile...'
                          : 'Loading Swopband Profile...',
                      style: AppTextStyles.medium.copyWith(
                        color: MyColors.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      /* floatingActionButton: widget.username != null
          ? FloatingActionButton.extended(
              onPressed: _connectWithUser,
              backgroundColor: MyColors.primaryColor,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'View Connections',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "Outfit"),
              ),
            )
          : null,*/
    );
  }

  /// Handle phone and email URLs from webview
  bool _handlePhoneOrEmailUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Handle phone URLs (tel:)
      if (uri.scheme == 'tel') {
        log('📞 Phone URL detected: $url');
        _launchPhone(uri.toString());
        return true;
      }

      // Handle email URLs (mailto:)
      if (uri.scheme == 'mailto') {
        log('📧 Email URL detected: $url');
        _launchEmail(uri.toString());
        return true;
      }

      // Handle SMS URLs (sms:)
      if (uri.scheme == 'sms') {
        log('💬 SMS URL detected: $url');
        _launchSMS(uri.toString());
        return true;
      }

      // Handle WhatsApp URLs (whatsapp:)
      if (uri.scheme == 'whatsapp') {
        log('💬 WhatsApp URL detected: $url');
        _launchWhatsApp(uri.toString());
        return true;
      }

      // Handle Telegram URLs (telegram:)
      if (uri.scheme == 'telegram') {
        log('💬 Telegram URL detected: $url');
        _launchTelegram(uri.toString());
        return true;
      }

      return false;
    } catch (e) {
      log('❌ Error handling URL: $url - $e');
      return false;
    }
  }

  /// Launch phone dialer
  Future<void> _launchPhone(String phoneUrl) async {
    try {
      final uri = Uri.parse(phoneUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        log('✅ Phone launched successfully: $phoneUrl');
      } else {
        log('❌ Cannot launch phone URL: $phoneUrl');
        SnackbarUtil.showError("Cannot open phone dialer");
      }
    } catch (e) {
      log('❌ Error launching phone: $e');
      SnackbarUtil.showError("Error opening phone dialer: $e");
    }
  }

  /// Launch email client
  Future<void> _launchEmail(String emailUrl) async {
    try {
      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        log('✅ Email launched successfully: $emailUrl');
      } else {
        log('❌ Cannot launch email URL: $emailUrl');
        SnackbarUtil.showError("Cannot open email client");
      }
    } catch (e) {
      log('❌ Error launching email: $e');
      SnackbarUtil.showError("Error opening email client: $e");
    }
  }

  /// Launch SMS client
  Future<void> _launchSMS(String smsUrl) async {
    try {
      final uri = Uri.parse(smsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        log('✅ SMS launched successfully: $smsUrl');
      } else {
        log('❌ Cannot launch SMS URL: $smsUrl');
        SnackbarUtil.showError("Cannot open SMS client");
      }
    } catch (e) {
      log('❌ Error launching SMS: $e');
      SnackbarUtil.showError("Error opening SMS client: $e");
    }
  }

  /// Launch WhatsApp
  Future<void> _launchWhatsApp(String whatsappUrl) async {
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        log('✅ WhatsApp launched successfully: $whatsappUrl');
      } else {
        log('❌ Cannot launch WhatsApp URL: $whatsappUrl');
        SnackbarUtil.showError("Cannot open WhatsApp");
      }
    } catch (e) {
      log('❌ Error launching WhatsApp: $e');
      SnackbarUtil.showError("Error opening WhatsApp: $e");
    }
  }

  /// Launch Telegram
  Future<void> _launchTelegram(String telegramUrl) async {
    try {
      final uri = Uri.parse(telegramUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        log('✅ Telegram launched successfully: $telegramUrl');
      } else {
        log('❌ Cannot launch Telegram URL: $telegramUrl');
        SnackbarUtil.showError("Cannot open Telegram");
      }
    } catch (e) {
      log('❌ Error launching Telegram: $e');
      SnackbarUtil.showError("Error opening Telegram: $e");
    }
  }

  Future<void> _autoConnectWithUser() async {
    if (widget.username == null) return;

    try {
      log('🔗 Auto-connecting with @${widget.username}');

      // Check if already connected
      if (_recentSwoppersController.isUserConnected(widget.username!)) {
        log('ℹ️ Already connected with @${widget.username}');
        return;
      }

      // Create connection automatically (no user interaction needed)
      final success =
          await _recentSwoppersController.createConnection(widget.username!);

      if (success) {
        log('✅ Auto-connected with @${widget.username} successfully!');
        SnackbarUtil.showSuccess("Connected with @${widget.username}!");
        // DO NOT navigate away - stay on profile page
      } else {
        log('❌ Auto-connection failed for @${widget.username}');
        SnackbarUtil.showError("Failed to connect with @${widget.username}");
      }
    } catch (e) {
      log('❌ Error in auto-connection: $e');
      SnackbarUtil.showError("Error connecting: $e");
    }
  }

  void _goToRecentSwoppers() {
    log('🔄 Navigating to Recent Swoppers screen');
    // Navigate to BottomNavScreen and set it to Recent Swoppers tab
    Get.offAll(() => BottomNavScreen());

    // Set the navigation to Recent Swoppers tab (index 1)
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        final navController = Get.find<NavController>();
        navController.selectedIndex.value = 1; // Recent Swoppers tab
        log('✅ Set navigation to Recent Swoppers tab');
      } catch (e) {
        log('❌ Error setting navigation tab: $e');
      }
    });
  }
}
