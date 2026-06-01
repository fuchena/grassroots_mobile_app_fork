import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grassroots_field_trials/utils_service.dart';
import 'package:grassroots_field_trials/utils_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _openGlobusWebView() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobusWebViewLogin(key: UniqueKey()),  //do we need a key here?
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF74C188),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/ICON1024.png", width: 150, height: 150),
                const SizedBox(height: 30),
                const Text(
                  "The Grassroots Field Trials App",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Login with Globus"),
                  onPressed: _openGlobusWebView,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlobusWebViewLogin extends StatefulWidget {
  final String url = UtilsService.GRASSROOTS_PAGE_URL;

  const GlobusWebViewLogin({super.key});

  @override
  State<GlobusWebViewLogin> createState() => _GlobusWebViewLoginState();
}

class _GlobusWebViewLoginState extends State<GlobusWebViewLogin> {
  String url = '';
  String title = '';
  double progress = 0;
  bool? isSecure;

  InAppWebViewController? webViewController;

  final _secureStorage = const FlutterSecureStorage();

  bool _disposed = false;
  bool _didNavigate = false;
  bool _logoutTriggered = false;

  void safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _navigateHome() async {
    if (_didNavigate || _disposed || !mounted) return;
    _didNavigate = true;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
    );
  }

  Future<void> _handleLogin(String cookie) async {
    try {
      final userInfo = await fetchUserInfo(cookie);
      final user = userInfo["user"];

      final email = user["so:email"];
      final name = '${user["so:givenName"]} ${user["so:familyName"]}';

      await _secureStorage.write(key: 'SESSION_COOKIE', value: cookie);
      await _secureStorage.write(key: 'USER_NAME', value: name);
      await _secureStorage.write(key: 'EMAIL', value: email);

      await _navigateHome();
    } catch (e) {
      print("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(UtilsService.GRASSROOTS_PAGE_URL),
                  ),
                  initialSettings: InAppWebViewSettings(
                    transparentBackground: true,
                    safeBrowsingEnabled: true,
                    isFraudulentWebsiteWarningEnabled: true,
                  ),

                  onWebViewCreated: (controller) async {
                    webViewController = controller;

                    if (_logoutTriggered) return;
                    if (_disposed || url == null) return;
                    _logoutTriggered = true; //check _logoutTriggered, _disposed and _didNavigate??

                    await _logoutAndReload();
                  },

                  onLoadStart: (controller, url) {
                    if (_disposed || url == null) return;

                    safeSetState(() {
                      this.url = url.toString();
                      isSecure = urlIsSecure(url);
                    });
                  },

                  onLoadStop: (controller, url) async {
                    if (_disposed || url == null || _didNavigate) return;

                    safeSetState(() {
                      this.url = url.toString();
                    });

                    if (!this.url.startsWith(
                        UtilsService.GRASSROOTS_PAGE_URL)) {
                      return;
                    }

                    final cookie = await getGrassrootsCookie();

                    if (cookie != null) {
                      await _handleLogin(cookie);
                    }
                  },

                  onUpdateVisitedHistory: (controller, url, _) {
                    if (_disposed || url == null) return;

                    safeSetState(() {
                      this.url = url.toString();
                    });
                  },

                  onTitleChanged: (controller, title) {
                    if (_disposed || title == null) return;

                    safeSetState(() {
                      this.title = title;
                    });
                  },

                  onProgressChanged: (controller, progress) {
                    safeSetState(() {
                      this.progress = progress / 100;
                    });
                  },

                  shouldOverrideUrlLoading: (controller, action) async {
                    final url = action.request.url;

                    if (url != null && !["http", "https", "file", "data", "javascript"].contains(url.scheme)) {
                      if (await canLaunchUrl(url)) {
                        launchUrl(url);
                        return NavigationActionPolicy.CANCEL;
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),

                if (progress < 1.0)
                  LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutAndReload() async {  //why not pass in the viewController?
    try {

      //destroys the setcookie
      await webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            '${UtilsService.GRASSROOTS_REDIRECT_URL}?logout=${UtilsService.GRASSROOTS_PAGE_URL}',
          ),
        ),
      );

      //await webViewController?.clearCache();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await webViewController?.clearHistory();
      }

      //opens the Globus login page
      await webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(UtilsService.GRASSROOTS_PAGE_URL),
        ),
      );
    } catch (e) {
      print("Logout error: $e");
    }
  }

  static bool urlIsSecure(Uri url) {
    return url.scheme == "https" || isLocal(url);
  }

  static bool isLocal(Uri url) {
    return ["file", "chrome", "data", "javascript", "about"].contains(url.scheme);
  }

  Future<dynamic> fetchUserInfo(String? cookie) async {
    final url = Uri.parse(UtilsService.USER_INFO_URL);

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Cookie': 'mod_auth_openidc_session=$cookie',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed user info: ${response.statusCode}',
    );
  }

  Future<String?> getGrassrootsCookie() async {
    final cookieManager = CookieManager.instance();

    final cookie = await cookieManager.getCookie(
      url: WebUri(UtilsService.GRASSROOTS_PAGE_URL),
      name: "mod_auth_openidc_session",
    );

    return cookie?.value;
  }
}