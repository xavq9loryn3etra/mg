import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'room_provider.dart';
import 'player_provider.dart';
import 'auth_provider.dart';
import 'package:firebase_database/firebase_database.dart';

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

final mafiaTeamProvider = StreamProvider.autoDispose<Map<String, String>>((ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  if (roomCode == null) return const Stream.empty();
  
  // We can't easily import firebase database without messing up dependencies here,
  // wait, game_service.dart uses it. Let's just import it at the top of game_provider.
  // Actually, I'll put the import in the next replacement chunk.
  return FirebaseDatabase.instance.ref('mafia_teams/$roomCode').onValue.map((event) {
    if (event.snapshot.value == null) return {};
    final map = event.snapshot.value as Map<dynamic, dynamic>;
    return map.map((k, v) => MapEntry(k.toString(), v.toString()));
  });
});
