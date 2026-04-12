class GameConfig {
  final int mafiaCount;
  final bool hasRabidDog;

  GameConfig({required this.mafiaCount, required this.hasRabidDog});

  factory GameConfig.fromJson(Map<dynamic, dynamic> json) {
    return GameConfig(
      mafiaCount: json['mafiaCount'] ?? 1,
      hasRabidDog: json['hasRabidDog'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'mafiaCount': mafiaCount, 'hasRabidDog': hasRabidDog};
  }
}
