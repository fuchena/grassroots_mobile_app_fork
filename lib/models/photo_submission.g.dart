// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_submission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhotoSubmissionAdapter extends TypeAdapter<PhotoSubmission> {
  @override
  final int typeId = 1;

  @override
  PhotoSubmission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhotoSubmission(
      filePath: fields[0] as String,
      plotId: fields[1] as String,
      studyId: fields[2] as String,
      plotNumber: fields[3] as int,
      date: fields[4] as String,
      syncStatus: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoSubmission obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.plotId)
      ..writeByte(2)
      ..write(obj.studyId)
      ..writeByte(3)
      ..write(obj.plotNumber)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoSubmissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
