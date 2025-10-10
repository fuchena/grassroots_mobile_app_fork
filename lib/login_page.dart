import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'globus_auth_service.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    bool credentialExist = await GlobusAuthService.isCredentialExist();
    if (credentialExist && mounted) {
      navigateToHome();
    }
  }

  Future<void> _openOrcidWebView(BuildContext context) async {
    await WebViewCookieManager().clearCookies(); // clear cookies/cache

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrcidWebViewLogin(
          onLoginSuccess: (idToken, email) async {
            await _secureStorage.write(key: 'GLOBUS_EMAIL', value: email);
            await _secureStorage.write(key: 'ID_TOKEN', value: idToken);

            if (!mounted) return;
            navigateToHome();
          },
          onLoginFailed: showSnackBar,
        ),
      ),
    );
  }

  void navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
          (_) => false,
    );
  }

  void showSnackBar(String content) {
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
                  "Welcome to the Grassroots Field Trials App",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Login with ORCID",
                      style: TextStyle(fontSize: 16)),
                  onPressed: () => _openOrcidWebView(context),
                ),
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
  final Future<void> Function(String idToken, String email) onLoginSuccess;
  final void Function(String error) onLoginFailed;

  const OrcidWebViewLogin({
    Key? key,
    required this.onLoginSuccess,
    required this.onLoginFailed,
  }) : super(key: key);

  @override
  State<OrcidWebViewLogin> createState() => _OrcidWebViewLoginState();
}

class _OrcidWebViewLoginState extends State<OrcidWebViewLogin> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _afterLogin = false;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    //authorization endpoint
    final authUrl = Uri.https(GlobusConfig.authBase, '/v2/oauth2/authorize', {
      'response_type': 'code',
      'client_id': GlobusConfig.clientId,
      'redirect_uri': GlobusConfig.redirectUri,
      'scope': 'openid email',
      'access_type': 'offline',
      'prompt': 'login',
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            if (request.url.startsWith(GlobusConfig.redirectUri)) {
              setState(() => _afterLogin = true);
              handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            setState(() => _afterLogin = false);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            widget.onLoginFailed('WebView: ${error.description}');
          },
        ),
      )
      ..loadRequest(authUrl).then((_) => _isWebViewReady =
      true); //callback runs after the Future returned by loadRequest()
  }

  Future<void> handleRedirect(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];

      if (code == null) {
        widget.onLoginFailed('No authorization code received');
        return;
      }

      final tokenData = await GlobusAuthService.exchangeCodeForToken(code);
      if (tokenData == null) {
        widget.onLoginFailed('Failed to exchange authorization code');
        return;
      }

      final accessToken = tokenData['access_token'] as String?;
      final idToken = tokenData['id_token'] as String?;

      if (accessToken == null || idToken == null) {
        widget.onLoginFailed('Invalid token response');
        return;
      }

      final email = await GlobusAuthService.fetchUserEmail(accessToken);

      if (email == null) {
        widget.onLoginFailed('Could not retrieve email address');
        return;
      }

      await widget.onLoginSuccess(idToken, email);
    } catch (e) {
      widget.onLoginFailed('Login failed: $e');
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grassroots"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Only show WebView if ready
          if (_isWebViewReady && !_isLoading)
            WebViewWidget(controller: _controller),

          // Show loading spinner before and after login
          if (_isLoading || _afterLogin)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
