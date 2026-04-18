// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playerNamesHash() => r'475c88b1e38116cbe87ad5e6a397582bc93fc28c';

/// See also [playerNames].
@ProviderFor(playerNames)
final playerNamesProvider =
    AutoDisposeStreamProvider<Map<String, PlayerNameItem>>.internal(
      playerNames,
      name: r'playerNamesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$playerNamesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerNamesRef =
    AutoDisposeStreamProviderRef<Map<String, PlayerNameItem>>;
String _$allPlayersHash() => r'11546ef52cfacf349cc5e8fe3c6674f09709c6a0';

/// See also [allPlayers].
@ProviderFor(allPlayers)
final allPlayersProvider =
    AutoDisposeStreamProvider<Map<String, Player>>.internal(
      allPlayers,
      name: r'allPlayersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allPlayersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPlayersRef = AutoDisposeStreamProviderRef<Map<String, Player>>;
String _$pendingPlayersHash() => r'538f6f0e4ebd2f7da2013c3ca1b95ef268e9c686';

/// See also [pendingPlayers].
@ProviderFor(pendingPlayers)
final pendingPlayersProvider =
    AutoDisposeStreamProvider<Map<String, PlayerNameItem>>.internal(
      pendingPlayers,
      name: r'pendingPlayersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingPlayersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingPlayersRef =
    AutoDisposeStreamProviderRef<Map<String, PlayerNameItem>>;
String _$myPlayerHash() => r'49b035cd7b3bf09ad82d34b4f54a02369fd73a16';

/// See also [myPlayer].
@ProviderFor(myPlayer)
final myPlayerProvider = AutoDisposeStreamProvider<Player?>.internal(
  myPlayer,
  name: r'myPlayerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myPlayerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyPlayerRef = AutoDisposeStreamProviderRef<Player?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
