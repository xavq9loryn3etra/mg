class Player {
  final String id;
  final String name;
  final String role;
  final bool isAlive;
  final int bites;
  final bool protectedByDoctor;

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.isAlive,
    required this.bites,
    required this.protectedByDoctor,
  });

  factory Player.fromJson(Map<dynamic, dynamic> json, String id) {
    return Player(
      id: id,
      name: json['name'] ?? '',
      role: json['role'] ?? 'unassigned',
      isAlive: json['isAlive'] ?? true,
      bites: json['bites'] ?? 0,
      protectedByDoctor: json['protectedByDoctor'] ?? false,
    );
  }
}

class PlayerNameItem {
  final String id;
  final String name;
  final bool isAlive;
  final String role;

  PlayerNameItem({required this.id, required this.name, required this.isAlive, required this.role});

  factory PlayerNameItem.fromJson(Map<dynamic, dynamic> json, String id) {
    return PlayerNameItem(
      id: id,
      name: json['name'] ?? '',
      isAlive: json['isAlive'] ?? true,
      role: json['role'] ?? 'unassigned',
    );
  }
}
