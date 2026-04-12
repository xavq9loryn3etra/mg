import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import 'room_provider.dart';
import 'auth_provider.dart';

part 'player_provider.g.dart';

@riverpod
Stream<Map<String, PlayerNameItem>> playerNames(PlayerNamesRef ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  if (roomCode == null) return const Stream.empty();
  return ref.watch(databaseServiceProvider).playerNamesStream(roomCode);
}

@riverpod
Stream<Map<String, PlayerNameItem>> pendingPlayers(PendingPlayersRef ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  if (roomCode == null) return const Stream.empty();
  return ref.watch(databaseServiceProvider).pendingPlayersStream(roomCode);
}

@riverpod
Stream<Player?> myPlayer(MyPlayerRef ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  final user = ref.watch(authStateProvider).value;

  if (roomCode == null || user == null) return const Stream.empty();
  return ref.watch(databaseServiceProvider).myPlayerStream(roomCode, user.uid);
}
