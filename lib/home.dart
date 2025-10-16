import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:grassroots_field_trials/globus_auth_service.dart';
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
  String hps_djangoStatus = 'unknown';
  String hps_mongoStatus = 'unknown';
  String? userFirstName = "";

  @override
  void initState() {
    super.initState();
    getUserName();
    GrassrootsPageState.CheckAndUpdateAllowedStudyIDs();
    checkHealthStatus();
    _printLocalObservations(); // Fetch and print local observations
    _printLocalPhotoSubmissions();
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
      final bool old_health_status = _GetServerHealth(false);

      final healthStatus = await ApiRequests.fetchHealthStatus();
      print("Health status fetched: $healthStatus");
      setState(() {
        hps_djangoStatus = healthStatus['django'] ?? 'unknown';
        hps_mongoStatus = healthStatus['mongo'] ?? 'unknown';
      });

      bool new_health_status = _GetServerHealth(false);

      /* Are we back online? */
      if ((!old_health_status) && new_health_status) {
        /* Sync any locally-saved observations */
        SnackBar snack_bar = SnackBar(
          content: Text(
            'Syncing local data',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        );

        ScaffoldMessenger.of(context).showSnackBar(snack_bar);
        await Observation.SyncLocalObservations();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      print('Django: $hps_djangoStatus, Mongo: $hps_mongoStatus');
      // Show snackbar if server is unhealthy
      if (hps_djangoStatus != 'running' || hps_mongoStatus != 'available') {
        final String? app_url = GrassrootsConfig.GetPhotoReceiverURL();
        String error_message = "Error: No Grassroots Server has been specified";

        if (app_url != null) {
          error_message =
              "Warning: There is a problem with the server connection to ${app_url}. Error ${ApiRequests.latest_error}";
        } else {}

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
      setState(() {
        hps_djangoStatus = 'error';
        hps_mongoStatus = 'error';
      });
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

  bool _GetServerHealth(bool refresh_flag) {
    return ((hps_djangoStatus == 'running') &&
        (hps_mongoStatus == 'available'));
  }

  Future<void> getUserName() async {
    final firstName = (await GlobusAuthService.getFirstName())?.split('.')[0];
    setState(() {
      userFirstName = '$firstName!'; //concat firstname with !
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isServerHealthy = _GetServerHealth(false);
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            onPressed: () => GlobusAuthService.logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: checkHealthStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 150,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "Welcome to the Grassroots App \n $userFirstName",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Empowering agricultural research through technology",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.center,
                      overflowAlignment: OverflowBarAlignment.center,
                      spacing: 16,
                      overflowSpacing: 12,
                      children: [
                        _buildButton(
                          label: 'Browse\nAll Studies',
                          icon: Icons.folder_open,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => GrassrootsStudies()),
                            );
                          },
                        ),
                        _buildButton(
                          label: 'Create Study',
                          icon: Icons.add_circle_outline,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NewStudyPage()),
                            );
                          },
                        ),
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
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      label: Text(
        label,
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(180, 70),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void EmptyBox(final String name) async {
    await Hive.deleteBoxFromDisk(name);
  }
}
