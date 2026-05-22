import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `app_config/maintenance` — single source of truth for all apps.
class MaintenanceConfigModel {
  const MaintenanceConfigModel({
    required this.enabled,
    required this.mode,
    required this.affectedUserApp,
    required this.affectedVendorApp,
    required this.affectedDriverApp,
    required this.title,
    required this.subtitle,
    required this.message,
    this.reopenTime,
    required this.supportPhone,
    required this.supportEmail,
    required this.supportWhatsapp,
    required this.showRetryButton,
    required this.showSupportButton,
    required this.lottieUrl,
    required this.bannerImageUrl,
    required this.theme,
    required this.socialLinks,
    required this.engagement,
    required this.schedule,
    required this.areaAvailability,
    required this.driverSmartControl,
    required this.emergencyControls,
    required this.allowBrowsing,
    required this.allowOrders,
    required this.allowCart,
    required this.allowPayments,
    required this.legacyStoreActive,
    this.updatedAt,
    this.updatedBy,
  });

  static const collection = 'app_config';
  static const documentId = 'maintenance';

  final bool enabled;
  final String mode; // soft | hard | read_only
  final bool affectedUserApp;
  final bool affectedVendorApp;
  final bool affectedDriverApp;
  final LocalizedTextMap title;
  final LocalizedTextMap subtitle;
  final LocalizedTextMap message;
  final DateTime? reopenTime;
  final String supportPhone;
  final String supportEmail;
  final String supportWhatsapp;
  final bool showRetryButton;
  final bool showSupportButton;
  final String lottieUrl;
  final String bannerImageUrl;
  final String theme; // light | dark
  final Map<String, String> socialLinks;
  final MaintenanceEngagement engagement;
  final MaintenanceSchedule schedule;
  final AreaAvailability areaAvailability;
  final DriverSmartControl driverSmartControl;
  final EmergencyControls emergencyControls;
  final bool allowBrowsing;
  final bool allowOrders;
  final bool allowCart;
  final bool allowPayments;
  /// Mirrors legacy `admins/{id}.isActive` for backward compatibility.
  final bool legacyStoreActive;
  final DateTime? updatedAt;
  final String? updatedBy;

  static MaintenanceConfigModel get defaults => MaintenanceConfigModel(
        enabled: false,
        mode: 'soft',
        affectedUserApp: false,
        affectedVendorApp: false,
        affectedDriverApp: false,
        title: LocalizedTextMap.defaults('Quick Groceries Under Maintenance'),
        subtitle: LocalizedTextMap.defaults('We will be back shortly'),
        message: LocalizedTextMap.defaults('We are upgrading our servers'),
        supportPhone: '+919999999999',
        supportEmail: 'support@quickgroceries.com',
        supportWhatsapp: '',
        showRetryButton: true,
        showSupportButton: true,
        lottieUrl: '',
        bannerImageUrl: '',
        theme: 'light',
        socialLinks: const {},
        engagement: MaintenanceEngagement.defaults,
        schedule: MaintenanceSchedule.defaults,
        areaAvailability: AreaAvailability.defaults,
        driverSmartControl: DriverSmartControl.defaults,
        emergencyControls: EmergencyControls.defaults,
        allowBrowsing: true,
        allowOrders: true,
        allowCart: true,
        allowPayments: true,
        legacyStoreActive: true,
      );

  factory MaintenanceConfigModel.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    final affected = raw['affectedApps'] as Map<String, dynamic>? ?? {};
    return MaintenanceConfigModel(
      enabled: raw['enabled'] as bool? ?? raw['maintenance'] as bool? ?? false,
      mode: raw['mode']?.toString() ?? 'soft',
      affectedUserApp: affected['user'] as bool? ?? true,
      affectedVendorApp: affected['vendor'] as bool? ?? false,
      affectedDriverApp: affected['driver'] as bool? ?? false,
      title: LocalizedTextMap.fromMap(raw['title']),
      subtitle: LocalizedTextMap.fromMap(raw['subtitle']),
      message: LocalizedTextMap.fromMap(raw['message']),
      reopenTime: _parseDate(raw['reopenTime'] ?? raw['reopen_time']),
      supportPhone: raw['supportPhone']?.toString() ??
          raw['support_phone']?.toString() ??
          defaults.supportPhone,
      supportEmail: raw['supportEmail']?.toString() ??
          raw['support_email']?.toString() ??
          defaults.supportEmail,
      supportWhatsapp: raw['supportWhatsapp']?.toString() ?? '',
      showRetryButton: raw['showRetryButton'] as bool? ?? true,
      showSupportButton: raw['showSupportButton'] as bool? ?? true,
      lottieUrl: raw['lottieUrl']?.toString() ?? '',
      bannerImageUrl: raw['bannerImageUrl']?.toString() ?? '',
      theme: raw['theme']?.toString() ?? 'light',
      socialLinks: Map<String, String>.from(
        (raw['socialLinks'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        ),
      ),
      engagement: MaintenanceEngagement.fromMap(
        raw['engagement'] as Map<String, dynamic>?,
      ),
      schedule: MaintenanceSchedule.fromMap(
        raw['schedule'] as Map<String, dynamic>?,
      ),
      areaAvailability: AreaAvailability.fromMap(
        raw['areaAvailability'] as Map<String, dynamic>?,
      ),
      driverSmartControl: DriverSmartControl.fromMap(
        raw['driverSmartControl'] as Map<String, dynamic>?,
      ),
      emergencyControls: EmergencyControls.fromMap(
        raw['emergencyControls'] as Map<String, dynamic>?,
      ),
      allowBrowsing: raw['allowBrowsing'] as bool? ?? true,
      allowOrders: raw['allowOrders'] as bool? ?? true,
      allowCart: raw['allowCart'] as bool? ?? true,
      allowPayments: raw['allowPayments'] as bool? ?? true,
      legacyStoreActive: raw['legacyStoreActive'] as bool? ?? true,
      updatedAt: _parseDate(raw['updatedAt']),
      updatedBy: raw['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toWriteMap() {
    return {
      'maintenance': enabled,
      'enabled': enabled,
      'mode': mode,
      'affectedApps': {
        'user': affectedUserApp,
        'vendor': affectedVendorApp,
        'driver': affectedDriverApp,
        'admin': false,
      },
      'title': title.toMap(),
      'subtitle': subtitle.toMap(),
      'message': message.toMap(),
      if (reopenTime != null) 'reopenTime': reopenTime!.toUtc().toIso8601String(),
      'supportPhone': supportPhone,
      'supportEmail': supportEmail,
      'supportWhatsapp': supportWhatsapp,
      'showRetryButton': showRetryButton,
      'showSupportButton': showSupportButton,
      'lottieUrl': lottieUrl,
      'bannerImageUrl': bannerImageUrl,
      'theme': theme,
      'socialLinks': socialLinks,
      'engagement': engagement.toMap(),
      'schedule': schedule.toMap(),
      'areaAvailability': areaAvailability.toMap(),
      'driverSmartControl': driverSmartControl.toMap(),
      'emergencyControls': emergencyControls.toMap(),
      'allowBrowsing': allowBrowsing,
      'allowOrders': allowOrders,
      'allowCart': allowCart,
      'allowPayments': allowPayments,
      'legacyStoreActive': legacyStoreActive,
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  MaintenanceConfigModel copyWith({
    bool? enabled,
    String? mode,
    bool? affectedUserApp,
    bool? affectedVendorApp,
    bool? affectedDriverApp,
    LocalizedTextMap? title,
    LocalizedTextMap? subtitle,
    LocalizedTextMap? message,
    DateTime? reopenTime,
    bool clearReopenTime = false,
    String? supportPhone,
    String? supportEmail,
    String? supportWhatsapp,
    bool? showRetryButton,
    bool? showSupportButton,
    String? lottieUrl,
    String? bannerImageUrl,
    String? theme,
    Map<String, String>? socialLinks,
    MaintenanceEngagement? engagement,
    MaintenanceSchedule? schedule,
    AreaAvailability? areaAvailability,
    DriverSmartControl? driverSmartControl,
    EmergencyControls? emergencyControls,
    bool? allowBrowsing,
    bool? allowOrders,
    bool? allowCart,
    bool? allowPayments,
    bool? legacyStoreActive,
    String? updatedBy,
  }) {
    return MaintenanceConfigModel(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      affectedUserApp: affectedUserApp ?? this.affectedUserApp,
      affectedVendorApp: affectedVendorApp ?? this.affectedVendorApp,
      affectedDriverApp: affectedDriverApp ?? this.affectedDriverApp,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      message: message ?? this.message,
      reopenTime: clearReopenTime ? null : (reopenTime ?? this.reopenTime),
      supportPhone: supportPhone ?? this.supportPhone,
      supportEmail: supportEmail ?? this.supportEmail,
      supportWhatsapp: supportWhatsapp ?? this.supportWhatsapp,
      showRetryButton: showRetryButton ?? this.showRetryButton,
      showSupportButton: showSupportButton ?? this.showSupportButton,
      lottieUrl: lottieUrl ?? this.lottieUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      theme: theme ?? this.theme,
      socialLinks: socialLinks ?? this.socialLinks,
      engagement: engagement ?? this.engagement,
      schedule: schedule ?? this.schedule,
      areaAvailability: areaAvailability ?? this.areaAvailability,
      driverSmartControl: driverSmartControl ?? this.driverSmartControl,
      emergencyControls: emergencyControls ?? this.emergencyControls,
      allowBrowsing: allowBrowsing ?? this.allowBrowsing,
      allowOrders: allowOrders ?? this.allowOrders,
      allowCart: allowCart ?? this.allowCart,
      allowPayments: allowPayments ?? this.allowPayments,
      legacyStoreActive: legacyStoreActive ?? this.legacyStoreActive,
      updatedAt: updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

class LocalizedTextMap {
  const LocalizedTextMap({
    required this.en,
    required this.te,
    required this.hi,
    required this.ar,
  });

  final String en;
  final String te;
  final String hi;
  final String ar;

  static LocalizedTextMap defaults(String en) => LocalizedTextMap(
        en: en,
        te: en,
        hi: en,
        ar: en,
      );

  factory LocalizedTextMap.fromMap(dynamic raw) {
    if (raw is String) return defaults(raw);
    final m = raw as Map<String, dynamic>? ?? {};
    final en = m['en']?.toString() ?? m['en-US']?.toString() ?? '';
    return LocalizedTextMap(
      en: en.isNotEmpty ? en : 'Maintenance',
      te: m['te']?.toString() ?? m['te-IN']?.toString() ?? en,
      hi: m['hi']?.toString() ?? m['hi-IN']?.toString() ?? en,
      ar: m['ar']?.toString() ?? m['ar-SA']?.toString() ?? en,
    );
  }

  Map<String, String> toMap() => {'en': en, 'te': te, 'hi': hi, 'ar': ar};

  String forLocale(String localeCode) {
    final lc = localeCode.toLowerCase();
    if (lc.startsWith('te')) return te;
    if (lc.startsWith('hi')) return hi;
    if (lc.startsWith('ar')) return ar;
    return en;
  }
}

class MaintenanceEngagement {
  const MaintenanceEngagement({
    required this.showCoupons,
    required this.showOffers,
    required this.showReferral,
    required this.showComingSoon,
    required this.couponCodes,
    required this.offerHeadline,
  });

  final bool showCoupons;
  final bool showOffers;
  final bool showReferral;
  final bool showComingSoon;
  final List<String> couponCodes;
  final String offerHeadline;

  static const defaults = MaintenanceEngagement(
    showCoupons: true,
    showOffers: true,
    showReferral: true,
    showComingSoon: false,
    couponCodes: [],
    offerHeadline: 'Exclusive offers when we reopen',
  );

  factory MaintenanceEngagement.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return MaintenanceEngagement(
      showCoupons: m['showCoupons'] as bool? ?? true,
      showOffers: m['showOffers'] as bool? ?? true,
      showReferral: m['showReferral'] as bool? ?? true,
      showComingSoon: m['showComingSoon'] as bool? ?? false,
      couponCodes: List<String>.from(m['couponCodes'] ?? const []),
      offerHeadline: m['offerHeadline']?.toString() ?? defaults.offerHeadline,
    );
  }

  Map<String, dynamic> toMap() => {
        'showCoupons': showCoupons,
        'showOffers': showOffers,
        'showReferral': showReferral,
        'showComingSoon': showComingSoon,
        'couponCodes': couponCodes,
        'offerHeadline': offerHeadline,
      };
}

class MaintenanceSchedule {
  const MaintenanceSchedule({
    required this.enabled,
    required this.dailyOpenTime,
    required this.dailyCloseTime,
    required this.timezone,
    required this.weeklyHolidays,
    required this.festivalClosures,
    required this.emergencyClose,
    required this.autoReopen,
  });

  final bool enabled;
  final String dailyOpenTime; // HH:mm
  final String dailyCloseTime;
  final String timezone;
  final List<int> weeklyHolidays; // 1=Mon … 7=Sun (DateTime.weekday)
  final List<Map<String, String>> festivalClosures;
  final bool emergencyClose;
  final bool autoReopen;

  static const defaults = MaintenanceSchedule(
    enabled: false,
    dailyOpenTime: '08:00',
    dailyCloseTime: '22:00',
    timezone: 'Asia/Kolkata',
    weeklyHolidays: [],
    festivalClosures: [],
    emergencyClose: false,
    autoReopen: true,
  );

  factory MaintenanceSchedule.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return MaintenanceSchedule(
      enabled: m['enabled'] as bool? ?? false,
      dailyOpenTime: m['dailyOpenTime']?.toString() ?? '08:00',
      dailyCloseTime: m['dailyCloseTime']?.toString() ?? '22:00',
      timezone: m['timezone']?.toString() ?? 'Asia/Kolkata',
      weeklyHolidays: List<int>.from(m['weeklyHolidays'] ?? const []),
      festivalClosures: (m['festivalClosures'] as List<dynamic>? ?? [])
          .map((e) => Map<String, String>.from(
                (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
              ))
          .toList(),
      emergencyClose: m['emergencyClose'] as bool? ?? false,
      autoReopen: m['autoReopen'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'dailyOpenTime': dailyOpenTime,
        'dailyCloseTime': dailyCloseTime,
        'timezone': timezone,
        'weeklyHolidays': weeklyHolidays,
        'festivalClosures': festivalClosures,
        'emergencyClose': emergencyClose,
        'autoReopen': autoReopen,
      };
}

class AreaAvailability {
  const AreaAvailability({
    required this.enabled,
    required this.disabledPincodes,
    required this.disabledCities,
    required this.disabledZoneIds,
    this.maxDeliveryRadiusKm,
  });

  final bool enabled;
  final List<String> disabledPincodes;
  final List<String> disabledCities;
  final List<String> disabledZoneIds;
  final double? maxDeliveryRadiusKm;

  static const defaults = AreaAvailability(
    enabled: false,
    disabledPincodes: [],
    disabledCities: [],
    disabledZoneIds: [],
  );

  factory AreaAvailability.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return AreaAvailability(
      enabled: m['enabled'] as bool? ?? false,
      disabledPincodes: List<String>.from(m['disabledPincodes'] ?? const []),
      disabledCities: List<String>.from(m['disabledCities'] ?? const []),
      disabledZoneIds: List<String>.from(m['disabledZoneIds'] ?? const []),
      maxDeliveryRadiusKm: (m['maxDeliveryRadiusKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'disabledPincodes': disabledPincodes,
        'disabledCities': disabledCities,
        'disabledZoneIds': disabledZoneIds,
        if (maxDeliveryRadiusKm != null)
          'maxDeliveryRadiusKm': maxDeliveryRadiusKm,
      };
}

class DriverSmartControl {
  const DriverSmartControl({
    required this.enabled,
    required this.minDriversOnline,
    required this.autoPauseCod,
    required this.limitOrderDistanceKm,
    required this.pauseOrdering,
    required this.highDemandMessage,
  });

  final bool enabled;
  final int minDriversOnline;
  final bool autoPauseCod;
  final double limitOrderDistanceKm;
  final bool pauseOrdering;
  final LocalizedTextMap highDemandMessage;

  static final defaults = DriverSmartControl(
    enabled: true,
    minDriversOnline: 2,
    autoPauseCod: true,
    limitOrderDistanceKm: 8,
    pauseOrdering: true,
    highDemandMessage: LocalizedTextMap.defaults(
      'High demand — deliveries may be delayed',
    ),
  );

  factory DriverSmartControl.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return DriverSmartControl(
      enabled: m['enabled'] as bool? ?? true,
      minDriversOnline: m['minDriversOnline'] as int? ?? 2,
      autoPauseCod: m['autoPauseCod'] as bool? ?? true,
      limitOrderDistanceKm:
          (m['limitOrderDistanceKm'] as num?)?.toDouble() ?? 8,
      pauseOrdering: m['pauseOrdering'] as bool? ?? true,
      highDemandMessage: LocalizedTextMap.fromMap(m['highDemandMessage']),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'minDriversOnline': minDriversOnline,
        'autoPauseCod': autoPauseCod,
        'limitOrderDistanceKm': limitOrderDistanceKm,
        'pauseOrdering': pauseOrdering,
        'highDemandMessage': highDemandMessage.toMap(),
      };
}

class EmergencyControls {
  const EmergencyControls({
    required this.stopAllOrders,
    required this.disablePayments,
    required this.disableCod,
    required this.disableRegistrations,
    required this.disableGuestCheckout,
  });

  final bool stopAllOrders;
  final bool disablePayments;
  final bool disableCod;
  final bool disableRegistrations;
  final bool disableGuestCheckout;

  static const defaults = EmergencyControls(
    stopAllOrders: false,
    disablePayments: false,
    disableCod: false,
    disableRegistrations: false,
    disableGuestCheckout: false,
  );

  factory EmergencyControls.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return EmergencyControls(
      stopAllOrders: m['stopAllOrders'] as bool? ?? false,
      disablePayments: m['disablePayments'] as bool? ?? false,
      disableCod: m['disableCod'] as bool? ?? false,
      disableRegistrations: m['disableRegistrations'] as bool? ?? false,
      disableGuestCheckout: m['disableGuestCheckout'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'stopAllOrders': stopAllOrders,
        'disablePayments': disablePayments,
        'disableCod': disableCod,
        'disableRegistrations': disableRegistrations,
        'disableGuestCheckout': disableGuestCheckout,
      };
}
