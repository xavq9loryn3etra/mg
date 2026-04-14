// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playerNamesHash() => r'34d75813e1d0c07fdc350df11eae69aa8d7ada47';

/// See also [playerNames].
@ProviderFor(playerNames)
final playerNamesProvider =
    AutoDisposeStreamProvider<Map<String, PlayerNameItem>>.internal(
  playerNames,
  name: r'playerNamesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerNamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PlayerNamesRef
    = AutoDisposeStreamProviderRef<Map<String, PlayerNameItem>>;
String _$allPlayersHash() => r'all_players_custom_hash';

/// See also [allPlayers].
@ProviderFor(allPlayers)
final allPlayersProvider =
    AutoDisposeStreamProvider<Map<String, Player>>.internal(
  allPlayers,
  name: r'allPlayersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPlayersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllPlayersRef = AutoDisposeStreamProviderRef<Map<String, Player>>;

String _$pendingPlayersHash() => r'5c3d63b02d950c50e77da42419b3d6fe908af8ed';

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

typedef PendingPlayersRef
    = AutoDisposeStreamProviderRef<Map<String, PlayerNameItem>>;
String _$myPlayerHash() => r'76c7e475dcee75d721f088293c4f461b42cdd28e';

/// See also [myPlayer].
@ProviderFor(myPlayer)
final myPlayerProvider = AutoDisposeStreamProvider<Player?>.internal(
  myPlayer,
  name: r'myPlayerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myPlayerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyPlayerRef = AutoDisposeStreamProviderRef<Player?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
