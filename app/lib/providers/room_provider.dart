import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/room.dart';

part 'room_provider.g.dart';

@riverpod
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService();
}

@riverpod
class CurrentRoomCode extends _$CurrentRoomCode {
  @override
  String? build() => null;

  void setCode(String code) => state = code;
}

@riverpod
Stream<Room?> roomStream(RoomStreamRef ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  if (roomCode == null) return const Stream.empty();

  return ref.watch(databaseServiceProvider).roomStream(roomCode);
}
