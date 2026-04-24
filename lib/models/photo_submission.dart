import 'package:hive/hive.dart';

part 'photo_submission.g.dart';

@HiveType(typeId: 1)
class PhotoSubmission {
  @HiveField(0)
  final String filePath;

  @HiveField(1)
  final String plotId;

  @HiveField(2)
  final String studyId;

  @HiveField(3)
  final int plotNumber;

  @HiveField(4)
  final String date;

  @HiveField(5)
  final String syncStatus;

  PhotoSubmission({
    required this.filePath,
    required this.plotId,
    required this.studyId,
    required this.plotNumber,
    required this.date,
    required this.syncStatus,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'plotId': plotId,
        'studyId': studyId,
        'plotNumber': plotNumber,
        'date': date,
        'syncStatus': syncStatus,
      };
}
