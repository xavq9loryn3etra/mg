import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Check if the user has an active session and return the room code and status if valid
  Future<Map<String, String>?> checkActiveSession() async {
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
    final status = roomData['status'] as String? ?? 'lobby';
    
    if (status == 'game_over') {
      await _db.ref('user_sessions/$uid').remove();
      return null;
    }

    return {
      'roomCode': roomCode,
      'status': status,
    };
  }

  Future<void> _updateLastActive(String roomCode) async {
    await _db.ref('rooms/$roomCode').update({'lastActive': ServerValue.timestamp});
  }

  /// Generate a random 5-character room code.
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
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

    const timestamp = ServerValue.timestamp;
    await _db.ref('rooms/$roomCode').set({
      'status': 'lobby',
      'hostId': uid,
      'nightCount': 0,
      'activeRole': null,
      'morningAnnouncement': null,
      'winner': null,
      'config': {
        'mafiaCount': 2,
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
    required int mafiaCount,
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
      'mafiaCount': mafiaCount,
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
    
    final mafiaCount = (config['mafiaCount'] as int?) ?? 2;
    for (var i = 0; i < mafiaCount; i++) {
      roles.add('mafia');
    }

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
      updates['players/$roomCode/$id/isReady'] = false;
      updates['player_names/$roomCode/$id/isAlive'] = true;
      updates['player_names/$roomCode/$id/isReady'] = false;
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
      await actionRef.child('detectiveScanResolved').set(false);
    }

    return null;
  }

  /// Narrator resolves the detective's scan so they can see the result.
  Future<void> resolveDetectiveScan(String roomCode) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in.');

    final roomSnap = await _db.ref('rooms/$roomCode/hostId').get();
    if (roomSnap.value != uid) throw Exception('Only host can resolve scans.');

    final nightSnap = await _db.ref('rooms/$roomCode/nightCount').get();
    final nightCount = nightSnap.value as int? ?? 0;
    
    // Look up who the detective scanned and compute the result
    final scanSnap = await _db.ref('night_actions/$roomCode/$nightCount/detectiveScan').get();
    final targetId = scanSnap.value as String?;
    
    String scanResult = 'villager';
    if (targetId != null) {
      final targetSnap = await _db.ref('players/$roomCode/$targetId/role').get();
      final targetRole = targetSnap.value as String? ?? 'villager';
      // Detective only identifies 'mafia'. Godfather, doctor, dog, villager all show as 'villager'.
      scanResult = (targetRole == 'mafia') ? 'mafia' : 'villager';
    }
    
    await _db.ref('night_actions/$roomCode/$nightCount').update({
      'detectiveScanResolved': true,
      'detectiveScanResult': scanResult,
    });
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

    final mafiaKills = <String>[];
    final rabiesKills = <String>[];

    // Resolve mafia kill
    if (actions['mafiaTarget'] != null) {
      final t = actions['mafiaTarget'] as String;
      if (players[t]?['protectedByDoctor'] != true) {
        updates['players/$roomCode/$t/isAlive'] = false;
        updates['player_names/$roomCode/$t/isAlive'] = false;
        players[t]?['isAlive'] = false;
        mafiaKills.add(players[t]?['name'] as String? ?? 'Unknown');
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
        final name = players[t]?['name'] ?? 'Unknown';
        rabiesKills.add(name);
        deaths.add(name);
      }
    }

    // Morning announcement logic
    String msg = '';
    if (deaths.isEmpty) {
      msg = 'The night was quiet. No one died.';
    } else {
      final List<String> bulletPoints = [];
      if (mafiaKills.isNotEmpty) {
        final gunshotPlural = mafiaKills.length == 1 ? 'gunshot' : 'gunshots';
        bulletPoints.add('The town was woken by ${mafiaKills.length} $gunshotPlural. ${mafiaKills.join(", ")} was found dead.');
      }
      if (rabiesKills.isNotEmpty) {
        bulletPoints.add('${rabiesKills.join(", ")} succumbed to rabies after being bitten.');
      }
      msg = bulletPoints.join(" ");
    }

    updates['rooms/$roomCode/morningAnnouncement'] = msg;
    
    // Check win condition BEFORE updating status
    final winUpdates = await _getWinConditionUpdates(roomCode, updates);
    if (winUpdates != null) {
      updates.addAll(winUpdates);
    } else {
      updates['rooms/$roomCode/status'] = 'day';
    }

    // Finalize all updates atomically using multi-path update
    await _db.ref().update(updates);
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

    // Check win condition after the vote elimination
    final winUpdates = await _getWinConditionUpdates(roomCode, updates);
    if (winUpdates != null) {
      updates.addAll(winUpdates);
    } else {
      updates['rooms/$roomCode/status'] = 'night';
      updates['rooms/$roomCode/nightCount'] = (room['nightCount'] as int) + 1;
      updates['rooms/$roomCode/activeRole'] = null;
    }

    // Group all updates into a single atomic multi-path update
    await _db.ref().update(updates);
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

  /// Internal helper to calculate win updates without performing a write.
  /// [pendingUpdates] allows us to account for players who are about to die in the same transaction.
  Future<Map<String, dynamic>?> _getWinConditionUpdates(String roomCode, [Map<String, dynamic>? pendingUpdates]) async {
    final playersSnap = await _db.ref('players/$roomCode').get();
    final playersRaw = (playersSnap.value as Map<dynamic, dynamic>?) ?? {};
    
    // Create a deep modifiable copy to prevent crashes when applying pending updates
    final players = <String, Map<String, dynamic>>{};
    playersRaw.forEach((k, v) {
      players[k.toString()] = Map<String, dynamic>.from(v as Map);
    });

    // Apply pending updates to the local map so we check the NEXT state
    if (pendingUpdates != null) {
      pendingUpdates.forEach((key, value) {
        if (key.contains('/isAlive')) {
           final parts = key.split('/');
           // Extract UID from path (e.g., "players/ROOM/UID/isAlive")
           final uid = parts.length >= 3 ? parts[2] : null;
           if (uid != null && players.containsKey(uid)) {
             players[uid]!['isAlive'] = value;
           }
        }
      });
    }

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
      // Game over: reveal all roles to the public player_names node
      final revealUpdates = <String, dynamic>{
        'rooms/$roomCode/status': 'game_over',
        'rooms/$roomCode/winner': 'village',
      };
      for (final entry in players.entries) {
        revealUpdates['player_names/$roomCode/${entry.key}/role'] = entry.value['role'];
      }
      return revealUpdates;
    } else if (mafiaCount >= villageCount) {
      // Game over: reveal all roles to the public player_names node
      final revealUpdates = <String, dynamic>{
        'rooms/$roomCode/status': 'game_over',
        'rooms/$roomCode/winner': 'mafia',
      };
      for (final entry in players.entries) {
        revealUpdates['player_names/$roomCode/${entry.key}/role'] = entry.value['role'];
      }
      return revealUpdates;
    }
    return null;
  }

  /// Clear the current user's session so they don't auto-reconnect to the room.
  Future<void> leaveSession() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.ref('user_sessions/$uid').remove();
  }

  /// Resets a mid-game room back to lobby state (clears roles, kills, etc.)
  Future<void> resetRoomToLobby(String roomCode) async {
    final uid = _uid;
    if (uid == null) return;
    
    final roomSnap = await _db.ref('rooms/$roomCode').get();
    if (!roomSnap.exists) return;
    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['hostId'] != uid) throw Exception('Only host can reset room.');

    final updates = <String, dynamic>{};
    updates['rooms/$roomCode/status'] = 'lobby';
    updates['rooms/$roomCode/morningAnnouncement'] = null;
    updates['rooms/$roomCode/activeRole'] = null;
    updates['rooms/$roomCode/votes'] = null;
    updates['rooms/$roomCode/nightCount'] = 0;
    updates['rooms/$roomCode/winner'] = null;
    
    // Clear all night actions for this room
    await _db.ref('night_actions/$roomCode').remove();
    
    // Reset all players in the room
    final playersSnap = await _db.ref('players/$roomCode').get();
    if (playersSnap.exists) {
      final players = playersSnap.value as Map<dynamic, dynamic>;
      for (var uid in players.keys) {
        updates['players/$roomCode/$uid/role'] = 'unassigned';
        updates['players/$roomCode/$uid/isReady'] = false;
        updates['players/$roomCode/$uid/bites'] = 0;
        updates['players/$roomCode/$uid/protectedByDoctor'] = false;
        updates['players/$roomCode/$uid/isAlive'] = true;
        updates['players/$roomCode/$uid/isAbandoned'] = false;
        
        updates['player_names/$roomCode/$uid/role'] = null;
        updates['player_names/$roomCode/$uid/isReady'] = false;
        updates['player_names/$roomCode/$uid/isAlive'] = true;
        updates['player_names/$roomCode/$uid/isAbandoned'] = false;
      }
    }
    
    await _db.ref().update(updates);
  }

  /// Combined method to terminate a room (delete data) or reset to lobby.
  Future<void> terminateRoom(String roomCode) async {
    final uid = _uid;
    if (uid == null) return;

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    if (!roomSnap.exists) return;

    final roomData = roomSnap.value as Map<dynamic, dynamic>;
    if (roomData['hostId'] != uid) return;

    final currentStatus = roomData['status'] as String?;
    
    if (currentStatus == 'lobby' || currentStatus == 'game_over') {
      // Terminate completely if in lobby or game over results
      await _db.ref('rooms/$roomCode').update({
        'status': 'game_over_terminated', // Specific status to trigger home redirect
      });
      // Actually remove it after a short delay or just remove it now
      await _db.ref('rooms/$roomCode').remove();
    } else {
      // Reset to lobby if mid-game
      await resetRoomToLobby(roomCode);
    }
  }


  /// Mark a player as ready (acknowledged their role)
  Future<void> setPlayerReady(String roomCode) async {
    final uid = _uid;
    if (uid == null) return;
    
    final updates = {
      'players/$roomCode/$uid/isReady': true,
      'player_names/$roomCode/$uid/isReady': true,
    };
    
    await _db.ref().update(updates);
  }

  /// Combined method to leave a room and handle mid-game status updates.
  Future<void> leaveRoom(String roomCode) async {
    final uid = _uid;
    if (uid == null) return;

    final roomSnap = await _db.ref('rooms/$roomCode').get();
    if (roomSnap.exists) {
      final roomData = roomSnap.value as Map<dynamic, dynamic>;
      final status = roomData['status'] as String?;

      // 1. If we are in the lobby or pending, just remove the record
      if (status == 'lobby') {
        await _db.ref('pending_players/$roomCode/$uid').remove();
        await _db.ref('players/$roomCode/$uid').remove();
        await _db.ref('player_names/$roomCode/$uid').remove();
      } 
      // 2. If the game has already started or is transitioning, mark the player as dead/abandoned
      else {
        final updates = {
          'players/$roomCode/$uid/isAlive': false,
          'players/$roomCode/$uid/isAbandoned': true,
          'player_names/$roomCode/$uid/isAlive': false,
          'player_names/$roomCode/$uid/isAbandoned': true,
        };
        await _db.ref().update(updates);
      }

    }

    // Always clear the user session to prevent auto-reconnect
    await leaveSession();
  }
}


