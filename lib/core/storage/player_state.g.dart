// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerSettingsAdapter extends TypeAdapter<PlayerSettings> {
  @override
  final typeId = 11;

  @override
  PlayerSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerSettings(
      soundEnabled: fields[0] == null ? true : fields[0] as bool,
      musicEnabled: fields[1] == null ? true : fields[1] as bool,
      hapticsEnabled: fields[2] == null ? true : fields[2] as bool,
      sfxVolume: fields[3] == null ? 1 : (fields[3] as num).toDouble(),
      musicVolume: fields[4] == null ? 1 : (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.soundEnabled)
      ..writeByte(1)
      ..write(obj.musicEnabled)
      ..writeByte(2)
      ..write(obj.hapticsEnabled)
      ..writeByte(3)
      ..write(obj.sfxVolume)
      ..writeByte(4)
      ..write(obj.musicVolume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerStateAdapter extends TypeAdapter<PlayerState> {
  @override
  final typeId = 10;

  @override
  PlayerState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerState(
      coins: fields[0] == null
          ? EconomyRules.startingCoins
          : (fields[0] as num).toInt(),
      settings: fields[1] == null
          ? const PlayerSettings()
          : fields[1] as PlayerSettings,
      deck: fields[2] == null ? const [] : (fields[2] as List).cast<int>(),
      wins: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      portalsOpened: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      shakeHintSeen: fields[5] == null ? false : fields[5] as bool,
      completedAlbums: fields[6] == null
          ? const []
          : (fields[6] as List).cast<int>(),
      demoUnlocked: fields[7] == null ? false : fields[7] as bool,
      forceNextLegendary: fields[8] == null ? false : fields[8] as bool,
      syncProgress: fields[9] == null
          ? const {}
          : (fields[9] as Map).cast<String, int>(),
      syncTotals: fields[10] == null
          ? const {}
          : (fields[10] as Map).cast<String, int>(),
      syncVersion: (fields[11] as num?)?.toInt(),
      syncedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerState obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.coins)
      ..writeByte(1)
      ..write(obj.settings)
      ..writeByte(2)
      ..write(obj.deck)
      ..writeByte(3)
      ..write(obj.wins)
      ..writeByte(4)
      ..write(obj.portalsOpened)
      ..writeByte(5)
      ..write(obj.shakeHintSeen)
      ..writeByte(6)
      ..write(obj.completedAlbums)
      ..writeByte(7)
      ..write(obj.demoUnlocked)
      ..writeByte(8)
      ..write(obj.forceNextLegendary)
      ..writeByte(9)
      ..write(obj.syncProgress)
      ..writeByte(10)
      ..write(obj.syncTotals)
      ..writeByte(11)
      ..write(obj.syncVersion)
      ..writeByte(12)
      ..write(obj.syncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OwnedCardAdapter extends TypeAdapter<OwnedCard> {
  @override
  final typeId = 12;

  @override
  OwnedCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnedCard(
      characterId: (fields[0] as num).toInt(),
      copies: (fields[1] as num).toInt(),
      firstObtainedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OwnedCard obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.characterId)
      ..writeByte(1)
      ..write(obj.copies)
      ..writeByte(2)
      ..write(obj.firstObtainedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnedCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
