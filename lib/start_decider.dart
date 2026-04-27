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
    bool credentialExist = await GlobusAuthService.isCredentialExist();
    //print('Credential exist: $credentialExist');
    setState(() {
      _credentialExist = credentialExist;
    });

    //GlobusConfig.globusUpdateConfig();

    setState(() {
      _isLoading = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF74C188),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _credentialExist ? const HomePage() : const LoginScreen();   //uncomment later
    //return HomePage();
  }
}
