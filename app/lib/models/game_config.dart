class GameConfig {
  final bool hasMafia1;
  final bool hasMafia2;
  final bool hasDoctor;
  final bool hasGodfather;
  final bool hasDetective;
  final bool hasRabidDog;

  GameConfig({
    required this.hasMafia1,
    required this.hasMafia2,
    required this.hasDoctor,
    required this.hasGodfather,
    required this.hasDetective,
    required this.hasRabidDog,
  });

  factory GameConfig.fromJson(Map<dynamic, dynamic> json) {
    return GameConfig(
      hasMafia1: json['hasMafia1'] ?? true,
      hasMafia2: json['hasMafia2'] ?? true,
      hasDoctor: json['hasDoctor'] ?? true,
      hasGodfather: json['hasGodfather'] ?? true,
      hasDetective: json['hasDetective'] ?? true,
      hasRabidDog: json['hasRabidDog'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasMafia1': hasMafia1,
      'hasMafia2': hasMafia2,
      'hasDoctor': hasDoctor,
      'hasGodfather': hasGodfather,
      'hasDetective': hasDetective,
      'hasRabidDog': hasRabidDog,
    };
  }
}
