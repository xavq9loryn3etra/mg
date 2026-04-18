class GameConfig {
  final int mafiaCount;
  final bool hasDoctor;
  final bool hasGodfather;
  final bool hasDetective;
  final bool hasRabidDog;

  GameConfig({
    required this.mafiaCount,
    required this.hasDoctor,
    required this.hasGodfather,
    required this.hasDetective,
    required this.hasRabidDog,
  });

  factory GameConfig.fromJson(Map<dynamic, dynamic> json) {
    return GameConfig(
      mafiaCount: json['mafiaCount'] ?? 2,
      hasDoctor: json['hasDoctor'] ?? true,
      hasGodfather: json['hasGodfather'] ?? true,
      hasDetective: json['hasDetective'] ?? true,
      hasRabidDog: json['hasRabidDog'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mafiaCount': mafiaCount,
      'hasDoctor': hasDoctor,
      'hasGodfather': hasGodfather,
      'hasDetective': hasDetective,
      'hasRabidDog': hasRabidDog,
    };
  }
}
