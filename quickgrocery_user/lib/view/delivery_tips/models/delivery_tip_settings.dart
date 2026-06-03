class DeliveryTipSettings {
  const DeliveryTipSettings({
    required this.enabled,
    required this.suggestedTips,
    required this.maxTipAmount,
  });

  final bool enabled;
  final List<int> suggestedTips;
  final int maxTipAmount;

  factory DeliveryTipSettings.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return DeliveryTipSettings.defaults();
    final tipsRaw = raw['suggestedTips'] ?? raw['suggested_tips'];
    final tips = tipsRaw is List
        ? tipsRaw
            .map((e) => (e is num ? e.round() : int.tryParse('$e') ?? 0))
            .where((e) => e > 0)
            .toList()
        : <int>[];
    return DeliveryTipSettings(
      enabled: raw['enabled'] != false,
      suggestedTips:
          tips.isNotEmpty ? tips : DeliveryTipSettings.defaults().suggestedTips,
      maxTipAmount: _int(raw['maxTipAmount'] ?? raw['max_tip_amount'], 500),
    );
  }

  factory DeliveryTipSettings.defaults() => const DeliveryTipSettings(
        enabled: true,
        suggestedTips: [10, 20, 50, 100],
        maxTipAmount: 500,
      );

  static int _int(dynamic v, int fallback) {
    if (v is num) return v.round();
    return int.tryParse('$v') ?? fallback;
  }
}
