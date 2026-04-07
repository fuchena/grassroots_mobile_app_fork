import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grassroots_field_trials/globus_auth_service.dart';
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
  @override
  void initState() {
    super.initState();
  }


  Future<void> _openGlobusWebView(BuildContext context) async {    //we can route directly to this page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobusWebViewLogin(key: UniqueKey()),
      ),
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
                      _openGlobusWebView(context);
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
class GlobusWebViewLogin extends StatefulWidget {
   final String url = GlobusAuthService.GRASSROOTS_PAGE_URL;

   GlobusWebViewLogin({super.key});
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
                  initialUrlRequest: URLRequest (url: WebUri(GlobusAuthService.GRASSROOTS_PAGE_URL)),
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
                      if (this.url.startsWith(GlobusAuthService.GRASSROOTS_PAGE_URL)) {
                        final cookie = await getGrassrootsCookie();
                        //debugPrint('mod_auth_openidc_session: $cookie');

                        // If no cookie, user is not authenticated
                        if (cookie != null) {
                          //debugPrint('No session cookie found. User not logged in.');

                          final claims = await fetchClaims(cookie);
                          final user = claims["user"];
                          final email = user["so:email"];
                          final givenName = user["so:givenName"];
                          final familyName = user["so:familyName"];
                          final name = '$givenName $familyName';

                          await _secureStorage.write(
                              key: 'SESSION_COOKIE', value: cookie);
                          await _secureStorage.write(
                              key: 'USER_NAME', value: name);
                          await _secureStorage.write(
                              key: 'EMAIL', value: email);

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => HomePage()),
                                  (_) => false,
                            );
                          }
                        }
                        return; // return?
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
      try {
        //final cookieManager = CookieManager.instance();

        //call Globus logout URL
        await webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('${GlobusAuthService.GRASSROOTS_REDIRECT_URL}?logout=${GlobusAuthService.GRASSROOTS_PAGE_URL}'),
          ),
        );

        //wait for logout to complete
        await Future.delayed(const Duration(seconds: 2));

        // clear ALL cookies (includes mod_auth_openidc)
        //await cookieManager.deleteAllCookies();

        //clear WebView cache/history
         await webViewController?.clearCache();
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          await webViewController?.clearHistory();
        }

        //load fresh login page
        await webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(GlobusAuthService.GRASSROOTS_PAGE_URL),
          ),
        );
      }
      catch (e) {
       // test exception handling here
        throw Exception('Error signing out: $e');
      }

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
    final url = Uri.parse(GlobusAuthService.USER_INFO_URL);
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

  Future <String?> getGrassrootsCookie () async {
    String? session_value = null;
    CookieManager cookie_manager = CookieManager.instance ();
    final grassroots_url = WebUri (GlobusAuthService.GRASSROOTS_PAGE_URL);
    final Cookie? cookie = await cookie_manager.getCookie(url: grassroots_url, name: "mod_auth_openidc_session");

    if (cookie != null) {
      session_value = cookie.value;
    }

    return session_value;
  }

}

