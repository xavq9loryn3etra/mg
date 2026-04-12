import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'room_provider.dart';
import 'player_provider.dart';
import 'auth_provider.dart';

part 'game_provider.g.dart';

@riverpod
bool isNarrator(IsNarratorRef ref) {
  final room = ref.watch(roomStreamProvider).value;
  final user = ref.watch(authStateProvider).value;
  if (room == null || user == null) return false;
  return room.hostId == user.uid;
}

@riverpod
bool isMyTurn(IsMyTurnRef ref) {
  final room = ref.watch(roomStreamProvider).value;
  final myPlayer = ref.watch(myPlayerProvider).value;

  if (room == null || myPlayer == null) return false;

  if (room.activeRole == 'mafia' &&
      (myPlayer.role == 'mafia' || myPlayer.role == 'godfather')) {
    return true;
  }

  return room.activeRole == myPlayer.role;
}
