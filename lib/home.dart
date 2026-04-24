import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:grassroots_field_trials/server.dart';
import 'login_page.dart';
import 'welcome_message.dart';
import 'grassroots_studies.dart';
import 'api_requests.dart';

import 'package:hive/hive.dart';
import 'models/observation.dart';
import 'models/photo_submission.dart';
import 'study_creator.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
/*  String hps_djangoStatus = 'unknown';
  String hps_mongoStatus = 'unknown';*/
  String? userFirstName = "";
  final ServerModel _model = ServerModel();
  final _secureStorage = const FlutterSecureStorage();
  final cookieManager = CookieManager.instance();
  @override
  void initState() {
    super.initState();
    _model.addListener(_handleModelUpdate);
    checkHealthStatus();
    getUserName();
    GrassrootsPageState.CheckAndUpdateAllowedStudyIDs();
    _printLocalObservations(); // Fetch and print local observations
    _printLocalPhotoSubmissions();
  }

  void _handleModelUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _model.removeListener(_handleModelUpdate);
    super.dispose();
  }

  Future<void> _printLocalPhotoSubmissions() async {
    try {
      var box =
          Hive.box<PhotoSubmission>('photo_submissions'); // Open the Hive box
      List<PhotoSubmission> photoSubmissions =
          box.values.toList(); // Get all photo submissions
      print('Local Photo Submissions:');
      for (var photo in photoSubmissions) {
        print(photo.toJson()); // Print each photo submission as JSON
      }
    } catch (e) {
      print('Error reading local photo submissions: $e');
    }
  }

  // New method to fetch and print local observations
  Future<void> _printLocalObservations() async {
    try {
      var box = Hive.box<Observation>('observations'); // Open the Hive box
      List<Observation> observations =
          box.values.toList(); // Get all observations
      print('Local Observations:');
      for (var observation in observations) {
        print(observation.toJson()); // Print each observation as JSON
      }
    } catch (e) {
      print('Error reading local observations: $e');
    }
  }

  Future<void> checkHealthStatus() async {
    print("checkHealthStatus called");
    try {
      await _model.checkStatus();
      if (!mounted) return;

      /* Are we back online? */
      if (_model.isOnline) {
        /* Sync any locally-saved observations */
        SnackBar snack_bar = SnackBar(
          content: Text(
            'Syncing local data',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snack_bar);
        await Observation.SyncLocalObservations();
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      // Show snackbar if server is unhealthy
      if (!_model.isOnline) {
        final String? app_url = GrassrootsConfig.GetPhotoReceiverURL();
        String error_message = "Error: No Grassroots Server has been specified";

        if (app_url != null) {
          error_message =
              "Warning: There is a problem with the server connection to ${app_url}. Error ${ApiRequests.latest_error}";
        } else {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            error_message,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ));
      }
    } catch (e) {
      print('>>>>> e: $e');
/*      setState(() {
        hps_djangoStatus = 'error';
        hps_mongoStatus = 'error';
      });*/
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error checking server status. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

/*  bool _GetServerHealth(bool refresh_flag) {
    return ((hps_djangoStatus == 'running') &&
        (hps_mongoStatus == 'available'));
  }*/

  Future<void> getUserName() async {
    String? firstName = await _secureStorage.read(key: 'USER_NAME');
    firstName = firstName?.split(' ')[0];
    if (!mounted) return;
    setState(() {
      userFirstName = (firstName== null ? "" : '$firstName!'); //concat firstname with !
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isServerHealthy = _model.isOnline;

    return Scaffold(
      //backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isServerHealthy ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isServerHealthy ? 'Server OK' : 'Server Issue',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Server Status',
            onPressed: checkHealthStatus,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => routeToLoginLogout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: checkHealthStatus,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                child: Padding( padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      Text(
                        "Welcome to the Grassroots App, $userFirstName",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Empowering agricultural research through technology",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // 👇 Centered Buttons Container
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            _buildButton(
                              label: 'Browse All Studies',
                              icon: Icons.folder_open,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => GrassrootsStudies()),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildButton(
                              label: 'Create Study',
                              icon: Icons.add_circle_outline,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => NewStudyPage()),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildButton(
                              label: 'Exit',
                              icon: Icons.exit_to_app,
                              onPressed: () => SystemNavigator.pop(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      WelcomeMessageWidget(),
                    ],
                  ),
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void EmptyBox(final String name) async {
    await Hive.deleteBoxFromDisk(name);
  }

  void routeToLoginLogout() async {
    await _secureStorage.deleteAll();
    await cookieManager.deleteAllCookies();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );


    }
  }
}
