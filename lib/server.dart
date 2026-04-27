import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_variable.dart';
import 'api_requests.dart';

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
      print("Django: $_djangoStatus | Mongo: $_mongoStatus");
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
    if (GrassrootsConfig.log_level >= LOG_INFO) print(message);
  }

  void _setUnknown(String message) {
    _djangoStatus = ServerStatus.unknown;
    _mongoStatus = ServerStatus.unknown;
    latestError = message;
    if (GrassrootsConfig.log_level >= LOG_INFO) print(message);
  }

}
