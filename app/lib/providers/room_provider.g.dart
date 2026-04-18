// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseServiceHash() => r'953b1020c1ad50a75b4605d375910af4a4c2e3cd';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseServiceRef = AutoDisposeProviderRef<DatabaseService>;
String _$roomStreamHash() => r'c93af403e6c7dffabd76453cffe1a825d9afb81c';

/// See also [roomStream].
@ProviderFor(roomStream)
final roomStreamProvider = AutoDisposeStreamProvider<Room?>.internal(
  roomStream,
  name: r'roomStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$roomStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
