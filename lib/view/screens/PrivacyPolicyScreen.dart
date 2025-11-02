
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final String url,type;

   const PrivacyPolicyScreen({super.key, required this.url, required this.type});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late WebViewController _controller;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title:  Text(
          widget.type,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                      'Loading Url..',
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
    );
  }
}