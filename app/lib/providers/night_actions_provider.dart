import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/night_actions.dart';
import 'room_provider.dart';

final nightActionsProvider = StreamProvider<NightActions?>((ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  // Watch the room for the nightCount
  final room = ref.watch(roomStreamProvider).value;
  
  if (roomCode == null || room == null) return const Stream.empty();
  
  return ref.watch(databaseServiceProvider).nightActionsStream(roomCode, room.nightCount);
});
