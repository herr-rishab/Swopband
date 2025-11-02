import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import for Android features
import 'package:webview_flutter_android/webview_flutter_android.dart';

// Import for iOS features
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late final WebViewController _controller;
  var loadingPercentage = 0;
  var isWebViewLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    // Platform-specific initialization
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              loadingPercentage = 0;
              isWebViewLoaded = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              loadingPercentage = 100;
              isWebViewLoaded = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              WebView Error:
              Code: ${error.errorCode}
              Description: ${error.description}
              Error Type: ${error.errorType}
              URL: ${error.url}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Block navigation to specific URLs
            if (request.url.contains('blocked-website.com')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://swopband.com'));

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Purchase Swopband",
          style: TextStyle(
            fontFamily: "Outfit",
          ),
        ),
      ),
      body: SafeArea(
        child: WebViewWidget(
          controller: _controller,
        ),
      ),
    );
  }
}
