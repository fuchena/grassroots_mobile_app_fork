import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'globals.dart';
import 'globus_auth_service.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _secureStorage = const FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    //_checkExistingLogin();
  }


  Future<void> _checkExistingLogin() async {
    bool credentialExist = await GlobusAuthService.isCredentialExist();
    if (credentialExist && mounted) {
      //navigateToHome();
    }
  }

  Future<void> _openOrcidWebView(BuildContext context) async {    //we can route directly to this page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrcidWebViewLogin(key: UniqueKey()),
      ),
          (route) => false,
    );
  }

  void showSnackBar(String content) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(content)));
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
                    label: const Text("Login with Globus",
                        style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      _openOrcidWebView(context);
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//WebView Login
class OrcidWebViewLogin extends StatefulWidget {
   final String url = GrassrootsAppGlobals.GRASSROOTS_URL;

   OrcidWebViewLogin({super.key});
  @override
  State<OrcidWebViewLogin> createState() => _OrcidWebViewLoginState();

}

class _OrcidWebViewLoginState extends State<OrcidWebViewLogin> {
  String url = '';
  String title = '';
  double progress = 0;
  bool? isSecure;
  InAppWebViewController? webViewController;
  final _secureStorage = const FlutterSecureStorage();
  final cookieManager = CookieManager.instance();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon (Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.fade,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isSecure != null
                            ? Icon(isSecure == true ? Icons.lock : Icons.lock_open,
                            color: isSecure == true ? Colors.green : Colors.red,
                            size: 12)
                            : Container(),
/*                        const SizedBox(
                          width: 5,
                        ),
                        Flexible(
                            child: Text(
                              url,
                              style:
                              const TextStyle(fontSize: 12, color: Colors.white70),
                              overflow: TextOverflow.fade,
                            )),*/
                      ],
                    )
                  ],
                )
            ),
          ],
        ),
      ),
      body: Column(children: <Widget>[
        Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  //initialUrlRequest: URLRequest (url: WebUri(widget.url)),
                  initialUrlRequest: URLRequest (url: WebUri(GrassrootsAppGlobals.GRASSROOTS_URL)),
                  initialSettings: InAppWebViewSettings (
                      transparentBackground: true,
                      safeBrowsingEnabled: true,
                      isFraudulentWebsiteWarningEnabled: true),
                  onWebViewCreated: (controller) async {
                    webViewController = controller;
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android) {
                        await controller.startSafeBrowsing();
                    }

                    // Trigger logout once when WebView is ready
                    _logoutAndReload();
                  },
                  onLoadStart: (controller, url) {
                    print('onLoadStart');
                    if (url != null) {
                      setState(() {
                        this.url = url.toString();
                        isSecure = urlIsSecure(url);
                      });
                    }
                  },
                  onLoadStop: (controller, url) async {
                    if (url != null) {
                      setState(() {
                        this.url = url.toString();
                      });
                      print("thisURL $url");
                      if (this.url.startsWith(GrassrootsAppGlobals.GRASSROOTS_URL)) {
                        String? cookie = await GetGrassrootsCookie();
                        print('mod_auth_openidc_session $cookie');
                        /*if (cookie==null) {

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(key: UniqueKey()),
                            ),
                                (route) => false,
                          );
                        } */
                        /*final claims = await fetchClaims(cookie);
                        final user = claims["user"];
                        final email = user["so:email"];
                        final givenName = user["so:givenName"];
                        final familyName = user["so:familyName"];
                        final name  = '$givenName $familyName';
                        print('fullname: $name'); */
                       // else {
                          if (context.mounted) {
                            navigateToHome();
                          }
                        //}

                        return;
                      }
                    }

                    final sslCertificate = await controller.getCertificate();
                    setState(() {
                      isSecure = sslCertificate != null ||
                          (url != null && urlIsSecure(url));
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) {
                    if (url != null) {
                      setState(() {
                        this.url = url.toString();
                      });
                    }
                  },
                  onTitleChanged: (controller, title) {
                    if (title != null) {
                      setState(() {
                        this.title = title;
                      });
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  onReceivedHttpError: (InAppWebViewController controller, WebResourceRequest request, WebResourceResponse errorResponse) {

                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url;
                    if (navigationAction.isForMainFrame &&
                        url != null &&
                        ![
                          'http',
                          'https',
                          'file',
                          'chrome',
                          'data',
                          'javascript',
                          'about'
                        ].contains(url.scheme)) {
                      if (await canLaunchUrl(url)) {
                        // Launch the App
                        launchUrl(url);
                        // and cancel the request
                        return NavigationActionPolicy.CANCEL;
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            )),
   /*     ElevatedButton(
          child: const Text('Clear'),
          onPressed: () {
            clear();
          },
        ),*/
      ]),

    );
  }

  Future<void> _logoutAndReload() async {

    final cookieManager = CookieManager.instance();

    // Step 1: Call Globus logout URL
    await webViewController?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri('https://auth.globus.org/v2/web/logout'),
      ),
    );

    // Wait for logout to complete
    await Future.delayed(const Duration(seconds: 2));

    // Step 2: Clear ALL cookies (includes mod_auth_openidc)
    await cookieManager.deleteAllCookies();

    // Step 3: Clear WebView cache/history
    await webViewController?.clearCache();
    await webViewController?.clearHistory();

    // Step 4: Load fresh login page
    await webViewController?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(GrassrootsAppGlobals.GRASSROOTS_URL),
      ),
    );
  }

  static bool urlIsSecure(Uri url) {
    return (url.scheme == "https") || isLocalizedContent(url);
  }

  static bool isLocalizedContent(Uri url) {
    return (url.scheme == "file" ||
        url.scheme == "chrome" ||
        url.scheme == "data" ||
        url.scheme == "javascript" ||
        url.scheme == "about");
  }

  Future<dynamic> fetchClaims(String? cookie) async {
    final url = Uri.parse(
      'https://grassroots.tools/dev/grassroots/private/backend/operation/get_all_services',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Cookie': 'mod_auth_openidc_session=$cookie',
        },
      );

      if (response.statusCode == 200) {
        // Decode JSON response
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future <String?> GetGrassrootsCookie () async {
    String? session_value = null;
    CookieManager cookie_manager = CookieManager.instance ();
    final grassroots_url = WebUri (GrassrootsAppGlobals.GRASSROOTS_URL);
    final Cookie? cookie = await cookie_manager.getCookie(url: grassroots_url, name: "mod_auth_openidc_session");

    if (cookie != null) {
      session_value = cookie.value;
    }

    return session_value;
  }

  void navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
          (_) => false,
    );
  }

}

