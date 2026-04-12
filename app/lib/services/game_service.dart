import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Check if the user has an active session and return the room code if valid
  Future<String?> checkActiveSession() async {
    final uid = _uid;
    if (uid == null) return null;

    final sessionSnap = await _db.ref('user_sessions/$uid').get();
    if (!sessionSnap.exists) return null;

    final session = sessionSnap.value as Map<dynamic, dynamic>;
    final roomCode = session['roomCode'] as String?;
    if (roomCode == null) return null;

    // Verify room still exists and isn't game over
    final roomSnap = await _db.ref('rooms/$roomCode').get();
    if (!roomSnap.exists) {
      await _db.ref('user_sessions/$uid').remove();
      return null;
    }

    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['status'] == 'game_over') {
      await _db.ref('user_sessions/$uid').remove();
      return null;
    }

    return roomCode;
  }

  Future<void> _updateLastActive(String roomCode) async {
    await _db.ref('rooms/$roomCode').update({'lastActive': ServerValue.timestamp});
  }

  /// Generate a random 5-character room code.
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    return String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  /// Create a new room. Returns the generated room code.
  Future<String> createRoom(String playerName) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');
    if (playerName.isEmpty) throw Exception('playerName required.');

    final roomCode = _generateRoomCode();

    final timestamp = ServerValue.timestamp;
    await _db.ref('rooms/$roomCode').set({
      'status': 'lobby',
      'hostId': uid,
      'nightCount': 0,
      'activeRole': null,
      'morningAnnouncement': null,
      'winner': null,
      'config': {
        'hasMafia1': true,
        'hasMafia2': true,
        'hasDoctor': true,
        'hasGodfather': true,
        'hasDetective': true,
        'hasRabidDog': true,
      },
      'lastActive': timestamp,
    });

    await _db.ref('user_sessions/$uid').set({
      'roomCode': roomCode,
      'lastActive': timestamp,
    });

    return roomCode;
  }

  /// Join an existing room as a player.
  Future<void> joinRoom(String roomCode, String playerName) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');
    if (roomCode.isEmpty || playerName.isEmpty) {
      throw Exception('roomCode and playerName required.');
    }

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    if (!roomSnap.exists) throw Exception('Room not found.');

    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['status'] != 'lobby') throw Exception('Game already started.');

    // If the user is the host (narrator), they don't join as a player
    if (roomData['hostId'] == uid) {
      // Just track their session
      await _db.ref('user_sessions/$uid').set({
        'roomCode': roomCode,
        'lastActive': ServerValue.timestamp,
      });
      return;
    }

    // Add to pending players instead of players directly
    await _db.ref('pending_players/$roomCode/$uid').set({
      'name': playerName,
      'requestedAt': ServerValue.timestamp,
    });
    
    // Track session so they can reconnect to the waiting room
    await _db.ref('user_sessions/$uid').set({
      'roomCode': roomCode,
      'lastActive': ServerValue.timestamp,
    });
  }

  /// Host approves a player to join the game
  Future<void> approvePlayer(String roomCode, String playerId, String playerName) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['hostId'] != uid) throw Exception('Only host can approve.');

    // Add to players
    await _db.ref('players/$roomCode/$playerId').set({
      'name': playerName,
      'isAlive': true,
      'bites': 0,
      'protectedByDoctor': false,
      'role': 'unassigned',
    });
    
    await _db.ref('player_names/$roomCode/$playerId').set({
      'name': playerName, 
      'isAlive': true
    });
    
    // Remove from pending
    await _db.ref('pending_players/$roomCode/$playerId').remove();
    
    // Update active time
    await _updateLastActive(roomCode);
  }

  /// Host rejects a player from joining
  Future<void> rejectPlayer(String roomCode, String playerId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['hostId'] != uid) throw Exception('Only host can reject.');

    await _db.ref('pending_players/$roomCode/$playerId').remove();
    await _db.ref('user_sessions/$playerId').remove(); // clear their session
  }

  /// Update game configuration (mafia count, rabid dog toggle).
  Future<void> configureGame(
    String roomCode, {
    required bool hasMafia1,
    required bool hasMafia2,
    required bool hasDoctor,
    required bool hasGodfather,
    required bool hasDetective,
    required bool hasRabidDog,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');
    if (roomCode.isEmpty) throw Exception('roomCode required.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host can configure.');
    if (room['status'] != 'lobby') throw Exception('Game already started.');

    await _db.ref('rooms/$roomCode/config').update({
      'hasMafia1': hasMafia1,
      'hasMafia2': hasMafia2,
      'hasDoctor': hasDoctor,
      'hasGodfather': hasGodfather,
      'hasDetective': hasDetective,
      'hasRabidDog': hasRabidDog,
    });
  }

  /// Start the game: validate player count, assign roles, transition to night.
  Future<void> startGame(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');
    if (roomCode.isEmpty) throw Exception('roomCode required.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host can start.');
    if (room['status'] != 'lobby') throw Exception('Game already started.');

    final playersSnap = await _db.ref('players/$roomCode').get();
    final players = (playersSnap.value as Map<dynamic, dynamic>?) ?? {};
    final playerIds = players.keys.cast<String>().toList();

    final config = (room['config'] as Map<dynamic, dynamic>?) ?? {};
    
    // Build role list
    final roles = <String>[];
    if (config['hasGodfather'] ?? true) roles.add('godfather');
    if (config['hasDoctor'] ?? true) roles.add('doctor');
    if (config['hasDetective'] ?? true) roles.add('detective');
    if (config['hasMafia1'] ?? true) roles.add('mafia');
    if (config['hasMafia2'] ?? true) roles.add('mafia');
    if (config['hasRabidDog'] ?? false) roles.add('rabid_dog');

    // Fill the rest with villagers
    while (roles.length < playerIds.length) {
      roles.add('villager');
    }

    // Shuffle roles
    final rng = Random();
    for (var i = roles.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = roles[i];
      roles[i] = roles[j];
      roles[j] = temp;
    }

    // Build updates
    final updates = <String, dynamic>{};
    for (var i = 0; i < playerIds.length; i++) {
      final id = playerIds[i];
      updates['players/$roomCode/$id/role'] = roles[i];
      updates['players/$roomCode/$id/protectedByDoctor'] = false;
      updates['players/$roomCode/$id/bites'] = 0;
      updates['players/$roomCode/$id/isAlive'] = true;
      updates['player_names/$roomCode/$id/isAlive'] = true;
    }

    updates['rooms/$roomCode/status'] = 'night';
    updates['rooms/$roomCode/nightCount'] = 1;
    updates['rooms/$roomCode/activeRole'] = null;
    updates['rooms/$roomCode/morningAnnouncement'] = 'The first night begins.';
    updates['rooms/$roomCode/lastActive'] = ServerValue.timestamp;

    // Extract mafia/godfather to a separate node for frontend filtering
    for (var i = 0; i < playerIds.length; i++) {
      final role = roles[i];
      if (role == 'mafia' || role == 'godfather') {
        updates['mafia_teams/$roomCode/${playerIds[i]}'] = role;
      }
    }

    for (var entry in updates.entries) {
      await _db.ref(entry.key).set(entry.value);
    }
  }

  /// Advance to the next night role (wake/sleep a role group).
  Future<void> advanceNightRole(String roomCode, String action) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host can advance nights.');
    if (room['status'] != 'night') throw Exception('Not night phase.');

    String? nextRole;
    if (action == 'wake_mafia') {
      nextRole = 'mafia';
    } else if (action == 'wake_doctor') {
      nextRole = 'doctor';
    } else if (action == 'wake_rabid_dog') {
      nextRole = 'rabid_dog';
    } else if (action == 'wake_detective') {
      nextRole = 'detective';
    } else if (action.startsWith('sleep_')) {
      nextRole = null;
    }

    await _db.ref('rooms/$roomCode').update({
      'activeRole': nextRole,
      'lastActive': ServerValue.timestamp,
    });
  }

  /// Submit a mafia member's vote for who to kill. Resolves when all mafia have voted.
  Future<void> submitMafiaVote(String roomCode, String targetId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;
    if (room['activeRole'] != 'mafia') throw Exception('Not mafia turn.');

    final myPlayerSnap = await _db.ref('players/$roomCode/$uid').get();
    final myPlayer = myPlayerSnap.value as Map<dynamic, dynamic>?;
    final myRole = myPlayer?['role'];
    if (myRole != 'mafia' && myRole != 'godfather') {
      throw Exception('Not a mafia.');
    }
    if (myPlayer?['isAlive'] != true) throw Exception('You are dead.');

    final targetSnap = await _db.ref('players/$roomCode/$targetId').get();
    final target = targetSnap.value as Map<dynamic, dynamic>?;
    if (target?['isAlive'] != true) throw Exception('Target is already dead.');

    final nightCount = room['nightCount'];
    await _db
        .ref('night_actions/$roomCode/$nightCount/mafiaVotes/$uid')
        .set(targetId);

    // Check if all alive mafia have voted
    final playersSnap = await _db.ref('players/$roomCode').get();
    final players = (playersSnap.value as Map<dynamic, dynamic>?) ?? {};

    final aliveMafiaUids = players.entries
        .where((e) {
          final p = e.value as Map<dynamic, dynamic>;
          return p['isAlive'] == true &&
              (p['role'] == 'mafia' || p['role'] == 'godfather');
        })
        .map((e) => e.key as String)
        .toList();

    final votesSnap = await _db
        .ref('night_actions/$roomCode/$nightCount/mafiaVotes')
        .get();
    final votes = (votesSnap.value as Map<dynamic, dynamic>?) ?? {};

    if (votes.length == aliveMafiaUids.length) {
      // Resolve majority vote
      final counts = <String, int>{};
      for (final v in votes.values) {
        final target = v as String;
        counts[target] = (counts[target] ?? 0) + 1;
      }

      var maxVote = 0;
      var maxTarget = '';
      var tie = false;

      for (final entry in counts.entries) {
        if (entry.value > maxVote) {
          maxVote = entry.value;
          maxTarget = entry.key;
          tie = false;
        } else if (entry.value == maxVote) {
          tie = true;
        }
      }

      var finalTarget = maxTarget;
      if (tie) {
        // Godfather's vote breaks ties
        final gfUid = aliveMafiaUids.cast<String>().firstWhere(
          (uid) =>
              (players[uid] as Map<dynamic, dynamic>)['role'] == 'godfather',
          orElse: () => '',
        );
        if (gfUid.isNotEmpty && votes.containsKey(gfUid)) {
          finalTarget = votes[gfUid] as String;
        }
      }

      await _db
          .ref('night_actions/$roomCode/$nightCount/mafiaTarget')
          .set(finalTarget);
    }
  }

  /// Submit a night action for doctor, rabid dog, or detective.
  /// Returns the scan result for the detective, or null for other roles.
  Future<String?> submitNightAction(String roomCode, String targetId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    final myPlayerSnap = await _db.ref('players/$roomCode/$uid').get();
    final me = myPlayerSnap.value as Map<dynamic, dynamic>?;
    if (room['activeRole'] != me?['role']) throw Exception('Not your turn.');
    if (me?['isAlive'] != true) throw Exception('You are dead.');

    final targetSnap = await _db.ref('players/$roomCode/$targetId').get();
    final target = targetSnap.value as Map<dynamic, dynamic>?;
    if (target?['isAlive'] != true) throw Exception('Target is dead.');

    final nightCount = room['nightCount'];
    final actionRef = _db.ref('night_actions/$roomCode/$nightCount');

    if (me?['role'] == 'doctor') {
      await actionRef.child('doctorTarget').set(targetId);
    } else if (me?['role'] == 'rabid_dog') {
      await actionRef.child('dogTarget').set(targetId);
    } else if (me?['role'] == 'detective') {
      await actionRef.child('detectiveScan').set(targetId);

      // Resolve scan immediately
      final targetRole = target?['role'] as String?;
      String result = 'Villager';
      if (targetRole == 'mafia' || targetRole == 'rabid_dog') {
        result = 'Mafia';
      }
      return result;
    }

    return null;
  }

  /// Resolve the night phase and transition to day. Applies kills, bites, protection.
  Future<void> revealMorning(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host.');
    if (room['status'] != 'night') throw Exception('Not night.');

    final nightCount = room['nightCount'];
    final actionsSnap = await _db
        .ref('night_actions/$roomCode/$nightCount')
        .get();
    final actions = (actionsSnap.value as Map<dynamic, dynamic>?) ?? {};

    final playersSnap = await _db.ref('players/$roomCode').get();
    final players = Map<String, Map<dynamic, dynamic>>.from(
      (playersSnap.value as Map<dynamic, dynamic>? ?? {}).map(
        (key, value) =>
            MapEntry(key as String, Map<dynamic, dynamic>.from(value as Map)),
      ),
    );

    final updates = <String, dynamic>{};
    final deaths = <String>[];

    // Reset protections from previous night
    for (final uid in players.keys) {
      if (players[uid]!['protectedByDoctor'] == true) {
        updates['players/$roomCode/$uid/protectedByDoctor'] = false;
      }
    }

    // Apply new doctor protection
    if (actions['doctorTarget'] != null) {
      final doctorTarget = actions['doctorTarget'] as String;
      updates['players/$roomCode/$doctorTarget/protectedByDoctor'] = true;
      players[doctorTarget]?['protectedByDoctor'] = true;
    }

    // Resolve mafia kill
    if (actions['mafiaTarget'] != null) {
      final t = actions['mafiaTarget'] as String;
      if (players[t]?['protectedByDoctor'] != true) {
        updates['players/$roomCode/$t/isAlive'] = false;
        updates['player_names/$roomCode/$t/isAlive'] = false;
        players[t]?['isAlive'] = false;
        deaths.add(players[t]?['name'] as String? ?? 'Unknown');
      }
    }

    // Resolve rabid dog bite
    if (actions['dogTarget'] != null) {
      final t = actions['dogTarget'] as String;
      final currentBites = (players[t]?['bites'] as int?) ?? 0;
      final newBites = currentBites + 1;
      updates['players/$roomCode/$t/bites'] = newBites;

      if (newBites >= 2) {
        updates['players/$roomCode/$t/isAlive'] = false;
        updates['player_names/$roomCode/$t/isAlive'] = false;
        players[t]?['isAlive'] = false;
        deaths.add('${players[t]?['name'] ?? 'Unknown'} (succumbed to rabies)');
      }
    }

    // Morning announcement
    final msg = deaths.isEmpty
        ? 'The night was quiet. No one died.'
        : 'Tragedy struck! ${deaths.join(', ')} died during the night.';

    updates['rooms/$roomCode/morningAnnouncement'] = msg;
    updates['rooms/$roomCode/status'] = 'day';

    for (var entry in updates.entries) {
      await _db.ref(entry.key).set(entry.value);
    }

    // Check win condition
    await _checkWinCondition(roomCode);
  }

  /// Start the voting phase.
  Future<void> startVoting(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host.');
    if (room['status'] != 'day') throw Exception('Not day phase.');

    // Clear previous votes
    await _db.ref('rooms/$roomCode/votes').remove();
    await _db.ref('rooms/$roomCode').update({'status': 'voting'});
  }

  /// Submit a player's day-phase vote.
  Future<void> submitVote(String roomCode, String targetId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;
    if (room['status'] != 'voting') throw Exception('Not voting phase.');

    final myPlayerSnap = await _db.ref('players/$roomCode/$uid').get();
    final me = myPlayerSnap.value as Map<dynamic, dynamic>?;
    if (me?['isAlive'] != true) throw Exception('Dead players cannot vote.');

    await _db.ref('rooms/$roomCode/votes/$uid').set(targetId);
  }

  /// Resolve day-phase votes: eliminate the majority target, then go to night.
  Future<void> resolveVotes(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host.');
    if (room['status'] != 'voting') throw Exception('Not voting phase.');

    final votesRaw = (room['votes'] as Map<dynamic, dynamic>?) ?? {};
    final counts = <String, int>{};
    for (final t in votesRaw.values) {
      final target = t as String;
      counts[target] = (counts[target] ?? 0) + 1;
    }

    var maxVote = 0;
    var maxTarget = '';
    var tie = false;

    for (final entry in counts.entries) {
      if (entry.value > maxVote) {
        maxVote = entry.value;
        maxTarget = entry.key;
        tie = false;
      } else if (entry.value == maxVote) {
        tie = true;
      }
    }

    final updates = <String, dynamic>{};
    if (tie || counts.isEmpty) {
      updates['rooms/$roomCode/morningAnnouncement'] =
          'The village was tied and decided to eliminate no one.';
    } else {
      updates['players/$roomCode/$maxTarget/isAlive'] = false;
      updates['player_names/$roomCode/$maxTarget/isAlive'] = false;
      updates['rooms/$roomCode/morningAnnouncement'] =
          'The village has voted to eliminate someone.';
    }

    updates['rooms/$roomCode/nightCount'] = (room['nightCount'] as int) + 1;
    updates['rooms/$roomCode/status'] = 'night';
    updates['rooms/$roomCode/activeRole'] = null;

    for (var entry in updates.entries) {
      await _db.ref(entry.key).set(entry.value);
    }
    await _checkWinCondition(roomCode);
  }

  /// Skip day discussion and go directly to night.
  Future<void> skipToNight(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    final room = roomSnap.value as Map<dynamic, dynamic>;

    if (room['hostId'] != uid) throw Exception('Only host.');

    await _db.ref('rooms/$roomCode').update({
      'status': 'night',
      'nightCount': (room['nightCount'] as int) + 1,
      'activeRole': null,
      'morningAnnouncement': 'The village went to sleep without voting.',
    });
  }

  /// Check if the game has ended (mafia eliminated or mafia >= villagers).
  Future<void> _checkWinCondition(String roomCode) async {
    final playersSnap = await _db.ref('players/$roomCode').get();
    final players = (playersSnap.value as Map<dynamic, dynamic>?) ?? {};

    var mafiaCount = 0;
    var villageCount = 0;

    for (final entry in players.values) {
      final p = entry as Map<dynamic, dynamic>;
      if (p['isAlive'] == true) {
        if (p['role'] == 'mafia' || p['role'] == 'godfather') {
          mafiaCount++;
        } else {
          villageCount++;
        }
      }
    }

    if (mafiaCount == 0) {
      await _db.ref('rooms/$roomCode').update({
        'status': 'game_over',
        'winner': 'village',
      });
    } else if (mafiaCount >= villageCount) {
      await _db.ref('rooms/$roomCode').update({
        'status': 'game_over',
        'winner': 'mafia',
      });
    }
  }

  /// Clear the current user's session so they don't auto-reconnect to the room.
  Future<void> leaveSession() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.ref('user_sessions/$uid').remove();
  }

  /// Terminate the room for everyone. Sets status to 'game_over'.
  Future<void> terminateRoom(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    if (!roomSnap.exists) return;
    
    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['hostId'] != uid) {
      throw Exception('Only the Host can terminate the room.');
    }

    await _db.ref('rooms/$roomCode').update({
      'status': 'game_over',
      'lastActive': ServerValue.timestamp,
    });
  }
}
