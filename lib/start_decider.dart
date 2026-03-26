import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/home.dart';
import 'package:grassroots_field_trials/login_page.dart';
import 'globus_auth_service.dart';

class StartDecider extends StatefulWidget {
  const StartDecider({super.key});

  @override
  State<StartDecider> createState() => _StartDeciderState();
}

class _StartDeciderState extends State<StartDecider> {
  bool _credentialExist = false;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    setState(() {
      _isLoading = false;
    });

    bool credentialExist = await GlobusAuthService.isCredentialExist();
    //print('Credential exist: $credentialExist');
    setState(() {
      _credentialExist = credentialExist;
    });

    GlobusConfig.globusUpdateConfig();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        backgroundColor: Color(0xFF74C188),
        body: Center(child: CircularProgressIndicator()),
      );

    return _credentialExist ? HomePage() : LoginScreen();   //uncomment later
    //return HomePage();
  }
}
