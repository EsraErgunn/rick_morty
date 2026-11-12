// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoredCharacterAdapter extends TypeAdapter<StoredCharacter> {
  @override
  final typeId = 1;

  @override
  StoredCharacter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredCharacter(
      id: (fields[0] as num).toInt(),
      name: fields[1] as String,
      status: fields[2] as String,
      species: fields[3] as String,
      subtype: fields[4] as String,
      gender: fields[5] as String,
      originName: fields[6] as String,
      originId: (fields[7] as num?)?.toInt(),
      locationName: fields[8] as String,
      locationId: (fields[9] as num?)?.toInt(),
      imageUrl: fields[10] as String,
      episodeIds: (fields[11] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, StoredCharacter obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.species)
      ..writeByte(4)
      ..write(obj.subtype)
      ..writeByte(5)
      ..write(obj.gender)
      ..writeByte(6)
      ..write(obj.originName)
      ..writeByte(7)
      ..write(obj.originId)
      ..writeByte(8)
      ..write(obj.locationName)
      ..writeByte(9)
      ..write(obj.locationId)
      ..writeByte(10)
      ..write(obj.imageUrl)
      ..writeByte(11)
      ..write(obj.episodeIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredCharacterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoredEpisodeAdapter extends TypeAdapter<StoredEpisode> {
  @override
  final typeId = 2;

  @override
  StoredEpisode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredEpisode(
      id: (fields[0] as num).toInt(),
      name: fields[1] as String,
      airDate: fields[2] as String,
      code: fields[3] as String,
      characterIds: (fields[4] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, StoredEpisode obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.airDate)
      ..writeByte(3)
      ..write(obj.code)
      ..writeByte(4)
      ..write(obj.characterIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredEpisodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoredLocationAdapter extends TypeAdapter<StoredLocation> {
  @override
  final typeId = 3;

  @override
  StoredLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredLocation(
      id: (fields[0] as num).toInt(),
      name: fields[1] as String,
      type: fields[2] as String,
      dimension: fields[3] as String,
      residentIds: (fields[4] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, StoredLocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.dimension)
      ..writeByte(4)
      ..write(obj.residentIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
