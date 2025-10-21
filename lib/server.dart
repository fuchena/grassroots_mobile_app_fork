import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_variable.dart';
import 'api_requests.dart';
import 'models/observation.dart';

/// Represents a simple label with an ID
class StringLabel {
  final String name;
  final String id;

  StringLabel(this.name, this.id);
}

typedef StringEntry = DropdownMenuEntry<StringLabel>;

/// Enumeration of server status states
enum ServerStatus { online, offline, unknown }

/// Centralized model to track server connectivity
class ServerModel extends ChangeNotifier {
  ServerStatus _djangoStatus = ServerStatus.unknown;
  ServerStatus _mongoStatus = ServerStatus.unknown;
  String latestError = "";

  bool get isOnline =>
      _djangoStatus == ServerStatus.online &&
      _mongoStatus == ServerStatus.online;

  Future<void> checkStatus() async {
    final previousStatus = isOnline;
    await _fetchHealthStatus();

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      debugPrint("Django: $_djangoStatus | Mongo: $_mongoStatus");
    }

    if (previousStatus != isOnline) {
      notifyListeners();
    }
  }

  Future<void> _fetchHealthStatus() async {
    final uri = ApiRequests.GetPhotoReceiverEndpoint("online_check/");
    if (uri == null) return;

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _setOffline("Non-200 response: ${response.statusCode}");
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      _djangoStatus = _parseStatus(data["django"], "running");
      _mongoStatus = _parseStatus(data["mongo"], "available");
    } catch (e) {
      _setUnknown("Error: $e");
    }
  }

  ServerStatus _parseStatus(String? value, String expected) {
    if (value == null) return ServerStatus.unknown;
    return value == expected ? ServerStatus.online : ServerStatus.offline;
  }

  void _setOffline(String message) {
    _djangoStatus = ServerStatus.offline;
    _mongoStatus = ServerStatus.offline;
    latestError = message;
    if (GrassrootsConfig.log_level >= LOG_INFO) debugPrint(message);
  }

  void _setUnknown(String message) {
    _djangoStatus = ServerStatus.unknown;
    _mongoStatus = ServerStatus.unknown;
    latestError = message;
    if (GrassrootsConfig.log_level >= LOG_INFO) debugPrint(message);
  }
}

/// Displays an AppBar with live server connection status
class ServerConnectionWidget extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  const ServerConnectionWidget({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ServerConnectionWidget> createState() => _ServerConnectionWidgetState();
}

class _ServerConnectionWidgetState extends State<ServerConnectionWidget> {
  final ServerModel _model = ServerModel();

  @override
  void initState() {
    super.initState();
    _model.addListener(() => setState(() {}));
    _checkHealthStatus(); // initial check
  }

  Future<void> _checkHealthStatus() async {
    try {
      await _model.checkStatus();

      if (_model.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server is online. Syncing local data...'),
            backgroundColor: Colors.green,
          ),
        );
        await Observation.SyncLocalObservations();
      } else {
        _showErrorSnackBar(
          "Server issue: ${ApiRequests.latest_error}",
        );
      }
    } catch (e) {
      _showErrorSnackBar("Error checking server: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = _model.isOnline;

    return AppBar(
      title: Text(widget.title),
      actions: [
        _StatusIndicator(isOnline: online),
        const SizedBox(width: 8),
        Text(
          online ? 'Server OK' : 'Server Issue',
          style: const TextStyle(fontSize: 14),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _checkHealthStatus,
          tooltip: 'Refresh Server Status',
        ),
      ],
    );
  }
}

/// Small circular LED indicator widget
class _StatusIndicator extends StatelessWidget {
  final bool isOnline;

  const _StatusIndicator({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.red,
      ),
    );
  }
}
