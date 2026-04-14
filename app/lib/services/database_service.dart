import 'package:firebase_database/firebase_database.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/night_actions.dart';


class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<Room?> roomStream(String roomCode) {
    return _db.ref('rooms/$roomCode').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Room.fromJson(
        event.snapshot.value as Map<dynamic, dynamic>,
        roomCode,
      );
    });
  }

  Stream<Map<String, PlayerNameItem>> playerNamesStream(String roomCode) {
    return _db.ref('player_names/$roomCode').onValue.map((event) {
      final value = event.snapshot.value as Map<dynamic, dynamic>?;
      if (value == null) return {};
      final map = <String, PlayerNameItem>{};
      value.forEach((key, val) {
        map[key as String] = PlayerNameItem.fromJson(
          val as Map<dynamic, dynamic>,
          key,
        );
      });
      return map;
    });
  }

  Stream<Map<String, PlayerNameItem>> pendingPlayersStream(String roomCode) {
    return _db.ref('pending_players/$roomCode').onValue.map((event) {
      final value = event.snapshot.value as Map<dynamic, dynamic>?;
      if (value == null) return {};
      final map = <String, PlayerNameItem>{};
      value.forEach((key, val) {
        // We can reuse PlayerNameItem since pending players just have 'name' and 'requestedAt'
        map[key as String] = PlayerNameItem.fromJson(
          val as Map<dynamic, dynamic>,
          key,
        );
      });
      return map;
    });
  }

  Stream<Player?> myPlayerStream(String roomCode, String uid) {
    return _db.ref('players/$roomCode/$uid').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Player.fromJson(
        event.snapshot.value as Map<dynamic, dynamic>,
        uid,
      );
    });
  }

  Stream<Map<String, Player>> allPlayersStream(String roomCode) {
    return _db.ref('players/$roomCode').onValue.map((event) {
      final value = event.snapshot.value as Map<dynamic, dynamic>?;
      if (value == null) return {};
      final map = <String, Player>{};
      value.forEach((key, val) {
        map[key as String] = Player.fromJson(
          val as Map<dynamic, dynamic>,
          key,
        );
      });
      return map;
    });
  }

  Stream<NightActions?> nightActionsStream(String roomCode, int nightCount) {
    return _db.ref('night_actions/$roomCode/$nightCount').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return NightActions.fromJson(event.snapshot.value as Map<dynamic, dynamic>);
    });
  }
}

