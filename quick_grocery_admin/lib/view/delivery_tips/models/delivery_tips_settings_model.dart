class DeliveryTipsSettingsModel {
  const DeliveryTipsSettingsModel({
    required this.enabled,
    required this.suggestedTips,
    required this.maxTipAmount,
  });

  final bool enabled;
  final List<int> suggestedTips;
  final int maxTipAmount;

  factory DeliveryTipsSettingsModel.defaults() =>
      const DeliveryTipsSettingsModel(
        enabled: true,
        suggestedTips: [10, 20, 50, 100],
        maxTipAmount: 500,
      );

  factory DeliveryTipsSettingsModel.fromMap(Map<String, dynamic>? m) {
    if (m == null) return DeliveryTipsSettingsModel.defaults();
    final raw = m['suggestedTips'] ?? m['suggested_tips'];
    final tips = raw is List
        ? raw
            .map((e) => (e is num ? e.round() : int.tryParse('$e') ?? 0))
            .where((e) => e > 0)
            .toList()
        : <int>[];
    return DeliveryTipsSettingsModel(
      enabled: m['enabled'] != false,
      suggestedTips:
          tips.isNotEmpty ? tips : DeliveryTipsSettingsModel.defaults().suggestedTips,
      maxTipAmount: _i(m['maxTipAmount'] ?? m['max_tip_amount'], 500),
    );
  }

  Map<String, dynamic> toCallablePayload() => {
        'enabled': enabled,
        'suggestedTips': suggestedTips,
        'maxTipAmount': maxTipAmount,
      };

  static int _i(dynamic v, int fb) {
    if (v is num) return v.round();
    return int.tryParse('$v') ?? fb;
  }
}

class DeliveryTipReportRow {
  const DeliveryTipReportRow({
    required this.orderId,
    required this.customerName,
    required this.deliveryPartnerId,
    required this.deliveryPartnerName,
    required this.tipAmount,
    required this.tipStatus,
    this.createdAt,
  });

  final String orderId;
  final String customerName;
  final String deliveryPartnerId;
  final String deliveryPartnerName;
  final double tipAmount;
  final String tipStatus;
  final DateTime? createdAt;

  factory DeliveryTipReportRow.fromMap(Map<String, dynamic> m) {
    DateTime? created;
    final raw = m['createdAt'];
    if (raw != null) {
      try {
        created = DateTime.parse(raw.toString());
      } catch (_) {}
    }
    return DeliveryTipReportRow(
      orderId: '${m['orderId'] ?? ''}',
      customerName: '${m['customerName'] ?? ''}',
      deliveryPartnerId: '${m['deliveryPartnerId'] ?? ''}',
      deliveryPartnerName: '${m['deliveryPartnerName'] ?? ''}',
      tipAmount: (m['tipAmount'] as num?)?.toDouble() ?? 0,
      tipStatus: '${m['tipStatus'] ?? 'pending'}',
      createdAt: created,
    );
  }
}

class DeliveryTipsDashboardStats {
  const DeliveryTipsDashboardStats({
    required this.totalTipsCollected,
    required this.tipsByDate,
    required this.topRiders,
    required this.orderCount,
  });

  final double totalTipsCollected;
  final List<MapEntry<String, double>> tipsByDate;
  final List<Map<String, dynamic>> topRiders;
  final int orderCount;
}
