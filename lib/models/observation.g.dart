// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ObservationAdapter extends TypeAdapter<Observation> {
  @override
  final int typeId = 0;

  @override
  Observation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Observation(
      plotId: fields[0] as String,
      trait: fields[1] as String,
      value: fields[2] as String,
      notes: fields[3] as String?,
      date: fields[4] as String,
      syncStatus: fields[5] as String,
      studyId: fields[6] as String,
      accession: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Observation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.plotId)
      ..writeByte(1)
      ..write(obj.trait)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.syncStatus)
      ..writeByte(6)
      ..write(obj.studyId)
      ..writeByte(7)
      ..write(obj.accession);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
