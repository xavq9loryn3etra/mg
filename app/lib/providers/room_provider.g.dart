// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseServiceHash() => r'766f41a8fb8947216fae68bbc31fa62d037f6899';

/// See also [databaseService].
@ProviderFor(databaseService)
final databaseServiceProvider = AutoDisposeProvider<DatabaseService>.internal(
  databaseService,
  name: r'databaseServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DatabaseServiceRef = AutoDisposeProviderRef<DatabaseService>;
String _$roomStreamHash() => r'd1cdbcbe4a42f9e28578bb53158cce83acac3867';

/// See also [roomStream].
@ProviderFor(roomStream)
final roomStreamProvider = AutoDisposeStreamProvider<Room?>.internal(
  roomStream,
  name: r'roomStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$roomStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RoomStreamRef = AutoDisposeStreamProviderRef<Room?>;
String _$currentRoomCodeHash() => r'09dfac14a1239a197f104bab02e5f87957809fc6';

/// See also [CurrentRoomCode].
@ProviderFor(CurrentRoomCode)
final currentRoomCodeProvider =
    AutoDisposeNotifierProvider<CurrentRoomCode, String?>.internal(
  CurrentRoomCode.new,
  name: r'currentRoomCodeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentRoomCodeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentRoomCode = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
