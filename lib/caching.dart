import 'package:grassroots_field_trials/global_variable.dart';
import 'package:hive/hive.dart';

/// Represents a simple model with an ID, name, and timestamp.
class IdName {
  final String name;
  final String id;
  final DateTime date;

  IdName({
    required this.name,
    required this.id,
    required this.date,
  });

  /// Factory constructor to build from JSON.
  factory IdName.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = DateTime.parse(json["date"] ?? '');
    } on FormatException {
      date = DateTime.now();
    }

    return IdName(
      name: json["name"] ?? '',
      id: json["id"] ?? '',
      date: date,
    );
  }
}

/// Hive adapter for IdName class.
class IdNameAdapter extends TypeAdapter<IdName> {
  @override
  final int typeId = 2;

  @override
  IdName read(BinaryReader reader) {
    final name = reader.readString();
    final id = reader.readString();
    final date = DateTime.parse(reader.readString());
    return IdName(name: name, id: id, date: date);
  }

  @override
  void write(BinaryWriter writer, IdName obj) {
    writer
      ..writeString(obj.name)
      ..writeString(obj.id)
      ..writeString(obj.date.toIso8601String());
  }
}

/// Handles caching of multiple IdName entries.
class IdNamesCache {
  /// Caches a list of studies or entities.
  static Future<void> cache(
      List<Map<String, String>> studies,
      String cacheName,
      ) async {
    final box = await Hive.openBox<IdName>(cacheName);
    final timestamp = DateTime.now();

    for (final entry in studies) {
      final name = entry['name'];
      final id = entry['id'];

      if (name != null && id != null) {
        final record = IdName(name: name, id: id, date: timestamp);
        await box.put(name, record);

        if (GrassrootsConfig.log_level >= LOG_FINER) {
          print('Cached IdName: $name -> $id');
        }
      }
    }

    await box.close();
  }
}

/// Represents a cached list of string IDs with a timestamp.
class IdsList {
  final List<String> ids;
  final DateTime date;

  IdsList({required this.ids, required this.date});
}

/// Hive adapter for IdsList class.
class IdsAdapter extends TypeAdapter<IdsList> {
  @override
  final int typeId = HI_ALLOWED_IDS;

  @override
  IdsList read(BinaryReader reader) {
    final ids = reader.readStringList();
    final date = DateTime.parse(reader.readString());
    return IdsList(ids: ids, date: date);
  }

  @override
  void write(BinaryWriter writer, IdsList obj) {
    writer
      ..writeStringList(obj.ids)
      ..writeString(obj.date.toIso8601String());
  }
}

/// Handles caching of ID lists.
class IdsCache {
  static const String cacheBox = "ids_cache";

  static Future<void> cacheIds(List<String> ids) async {
    final box = await Hive.openBox<IdsList>(cacheBox);
    final entry = IdsList(ids: ids, date: DateTime.now());

    await box.add(entry);

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      print('Cached ${ids.length} IDs at ${entry.date}');
    }

    await box.close();
  }
}

/// Handles generic caching of individual string IDs.
class IdCache {
  /// Returns the number of cached entries.
  static Future<int> getNumberOfEntries(String boxName) async {
    final box = await Hive.openBox<String>(boxName);
    final count = box.length;
    await box.close();
    return count;
  }

  /// Adds a single ID to a box.
  static Future<void> addId(String boxName, String id) async {
    final box = await Hive.openBox<String>(boxName);
    await box.add(id);

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print('Added ID $id to box $boxName');
    }

    await box.close();
  }

  /// Retrieves all cached IDs.
  static Future<List<String>> getAllEntries(String boxName) async {
    final box = await Hive.openBox<String>(boxName);
    final entries = List<String>.from(box.values);
    await box.close();

    if (GrassrootsConfig.log_level >= LOG_FINE) {
      print('Box $boxName has ${entries.length} IDs.');
    }

    return entries;
  }
}
