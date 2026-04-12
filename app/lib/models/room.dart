import 'game_config.dart';

class Room {
  final String code;
  final String status;
  final String hostId;
  final String? activeRole;
  final int nightCount;
  final String? morningAnnouncement;
  final String? winner;
  final GameConfig config;

  Room({
    required this.code,
    required this.status,
    required this.hostId,
    this.activeRole,
    required this.nightCount,
    this.morningAnnouncement,
    this.winner,
    required this.config,
  });

  factory Room.fromJson(Map<dynamic, dynamic> json, String code) {
    return Room(
      code: code,
      status: json['status'] ?? 'lobby',
      hostId: json['hostId'] ?? '',
      activeRole: json['activeRole'],
      nightCount: json['nightCount'] ?? 0,
      morningAnnouncement: json['morningAnnouncement'],
      winner: json['winner'],
      config: GameConfig.fromJson(json['config'] ?? {}),
    );
  }
}
