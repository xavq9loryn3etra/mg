class NightActions {
  final String? mafiaTarget;
  final String? doctorTarget;
  final String? dogTarget;
  final String? detectiveScan;
  final bool detectiveScanResolved;
  final String? detectiveScanResult;
  final Map<String, String> mafiaVotes;

  NightActions({
    this.mafiaTarget,
    this.doctorTarget,
    this.dogTarget,
    this.detectiveScan,
    this.detectiveScanResolved = false,
    this.detectiveScanResult,
    this.mafiaVotes = const {},
  });

  factory NightActions.fromJson(Map<dynamic, dynamic> json) {
    final votes = <String, String>{};
    if (json['mafiaVotes'] != null) {
      final votesRaw = json['mafiaVotes'] as Map<dynamic, dynamic>;
      votesRaw.forEach((key, value) {
        votes[key as String] = value as String;
      });
    }

    return NightActions(
      mafiaTarget: json['mafiaTarget'] as String?,
      doctorTarget: json['doctorTarget'] as String?,
      dogTarget: json['dogTarget'] as String?,
      detectiveScan: json['detectiveScan'] as String?,
      detectiveScanResolved: json['detectiveScanResolved'] ?? false,
      detectiveScanResult: json['detectiveScanResult'] as String?,
      mafiaVotes: votes,
    );
  }
}
