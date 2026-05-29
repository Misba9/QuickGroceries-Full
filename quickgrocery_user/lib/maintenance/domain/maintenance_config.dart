import 'package:cloud_firestore/cloud_firestore.dart';

/// Parsed from `app_config/maintenance`.
class MaintenanceConfig {
  const MaintenanceConfig({
    required this.enabled,
    required this.affectsUserApp,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.message,
    this.reopenTime,
    required this.supportPhone,
    required this.supportEmail,
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
    required this.storeOpen,
    required this.orderingEnabled,
    required this.userAppEnabled,
    required this.vendorAppEnabled,
    required this.driverAppEnabled,
    required this.usesSystemControls,
  });

  static const collection = 'maintenance';
  static const documentId = 'system';
  static const legacyCollection = 'app_config';
  static const legacyDocumentId = 'maintenance';

  final bool enabled;
  final bool affectsUserApp;
  final String mode;
  final LocalizedText title;
  final LocalizedText subtitle;
  final LocalizedText message;
  final DateTime? reopenTime;
  final String supportPhone;
  final String supportEmail;
  final bool showRetryButton;
  final bool showSupportButton;
  final String lottieUrl;
  final String bannerImageUrl;
  final String theme;
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
  final bool legacyStoreActive;
  final bool storeOpen;
  final bool orderingEnabled;
  final bool userAppEnabled;
  final bool vendorAppEnabled;
  final bool driverAppEnabled;
  final bool usesSystemControls;

  static final openDefaults = MaintenanceConfig(
    enabled: false,
    affectsUserApp: false,
    mode: 'soft',
    title: LocalizedText(en: 'Quick Groceries', te: '', hi: '', ar: ''),
    subtitle: LocalizedText(en: '', te: '', hi: '', ar: ''),
    message: LocalizedText(en: '', te: '', hi: '', ar: ''),
    supportPhone: '',
    supportEmail: '',
    showRetryButton: true,
    showSupportButton: true,
    lottieUrl: '',
    bannerImageUrl: '',
    theme: 'light',
    socialLinks: {},
    engagement: MaintenanceEngagement.defaults,
    schedule: MaintenanceSchedule.defaults,
    areaAvailability: AreaAvailability.defaults,
    driverSmartControl: DriverSmartControl.defaultsInstance,
    emergencyControls: EmergencyControls.defaults,
    allowBrowsing: true,
    allowOrders: true,
    allowCart: true,
    allowPayments: true,
    legacyStoreActive: true,
    storeOpen: true,
    orderingEnabled: true,
    userAppEnabled: true,
    vendorAppEnabled: true,
    driverAppEnabled: true,
    usesSystemControls: false,
  );

  factory MaintenanceConfig.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return openDefaults;
    final affected = raw['affectedApps'] as Map<String, dynamic>? ?? {};
    final usesSystemControls =
        raw.containsKey('storeOpen') ||
        raw.containsKey('store_open') ||
        raw.containsKey('orderingEnabled') ||
        raw.containsKey('ordering_enabled') ||
        raw.containsKey('maintenanceMode') ||
        raw.containsKey('userAppEnabled') ||
        raw.containsKey('vendorAppEnabled') ||
        raw.containsKey('driverAppEnabled');
    final storeOpen =
        raw['storeOpen'] as bool? ??
        raw['store_open'] as bool? ??
        raw['legacyStoreActive'] as bool? ??
        raw['isActive'] as bool? ??
        true;
    final orderingEnabled =
        raw['orderingEnabled'] as bool? ??
        raw['ordering_enabled'] as bool? ??
        raw['allowOrders'] as bool? ??
        true;
    final userAppEnabled =
        raw['userAppEnabled'] as bool? ??
        raw['user_app_enabled'] as bool? ??
        true;
    return MaintenanceConfig(
      enabled:
          raw['enabled'] as bool? ??
          raw['maintenanceMode'] as bool? ??
          raw['maintenance'] as bool? ??
          false,
      affectsUserApp: affected['user'] as bool? ?? true,
      mode: raw['mode']?.toString() ?? 'soft',
      title: LocalizedText.fromMap(raw['title']),
      subtitle: LocalizedText.fromMap(raw['subtitle']),
      message: LocalizedText.fromMap(raw['message']),
      reopenTime: _parseDate(raw['reopenTime'] ?? raw['reopen_time']),
      supportPhone:
          raw['supportPhone']?.toString() ??
          raw['support_phone']?.toString() ??
          '',
      supportEmail:
          raw['supportEmail']?.toString() ??
          raw['support_email']?.toString() ??
          '',
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
      allowOrders: orderingEnabled,
      allowCart: raw['allowCart'] as bool? ?? orderingEnabled,
      allowPayments: raw['allowPayments'] as bool? ?? orderingEnabled,
      legacyStoreActive: storeOpen,
      storeOpen: storeOpen,
      orderingEnabled: orderingEnabled,
      userAppEnabled: userAppEnabled,
      vendorAppEnabled:
          raw['vendorAppEnabled'] as bool? ??
          raw['vendor_app_enabled'] as bool? ??
          true,
      driverAppEnabled:
          raw['driverAppEnabled'] as bool? ??
          raw['driver_app_enabled'] as bool? ??
          true,
      usesSystemControls: usesSystemControls,
    );
  }

  /// API-shaped JSON for clients / debugging.
  Map<String, dynamic> toApiJson() => {
    'maintenance': enabled,
    'store_open': storeOpen,
    'ordering_enabled': orderingEnabled,
    'user_app_enabled': userAppEnabled,
    'uses_system_controls': usesSystemControls,
    'mode': mode,
    'title': title.forLocale('en'),
    'message': message.forLocale('en'),
    'allow_browsing': allowBrowsing,
    'reopen_time': reopenTime?.toUtc().toIso8601String(),
    'support_phone': supportPhone,
    'support_email': supportEmail,
  };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

class LocalizedText {
  const LocalizedText({
    required this.en,
    required this.te,
    required this.hi,
    required this.ar,
  });

  final String en;
  final String te;
  final String hi;
  final String ar;

  factory LocalizedText.fromMap(dynamic raw) {
    if (raw is String) {
      return LocalizedText(en: raw, te: raw, hi: raw, ar: raw);
    }
    final m = raw as Map<String, dynamic>? ?? {};
    final en = m['en']?.toString() ?? '';
    return LocalizedText(
      en: en,
      te: m['te']?.toString() ?? en,
      hi: m['hi']?.toString() ?? en,
      ar: m['ar']?.toString() ?? en,
    );
  }

  String forLocale(String localeCode) {
    final lc = localeCode.toLowerCase();
    if (lc.startsWith('te')) return te.isNotEmpty ? te : en;
    if (lc.startsWith('hi')) return hi.isNotEmpty ? hi : en;
    if (lc.startsWith('ar')) return ar.isNotEmpty ? ar : en;
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
    offerHeadline: '',
  );

  factory MaintenanceEngagement.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return MaintenanceEngagement(
      showCoupons: m['showCoupons'] as bool? ?? true,
      showOffers: m['showOffers'] as bool? ?? true,
      showReferral: m['showReferral'] as bool? ?? true,
      showComingSoon: m['showComingSoon'] as bool? ?? false,
      couponCodes: List<String>.from(m['couponCodes'] ?? const []),
      offerHeadline: m['offerHeadline']?.toString() ?? '',
    );
  }
}

class MaintenanceSchedule {
  const MaintenanceSchedule({
    required this.enabled,
    required this.dailyOpenTime,
    required this.dailyCloseTime,
    required this.weeklyHolidays,
    required this.emergencyClose,
    required this.autoReopen,
    required this.festivalClosures,
  });

  final bool enabled;
  final String dailyOpenTime;
  final String dailyCloseTime;
  final List<int> weeklyHolidays;
  final bool emergencyClose;
  final bool autoReopen;
  final List<Map<String, String>> festivalClosures;

  static const defaults = MaintenanceSchedule(
    enabled: false,
    dailyOpenTime: '08:00',
    dailyCloseTime: '22:00',
    weeklyHolidays: [],
    emergencyClose: false,
    autoReopen: true,
    festivalClosures: [],
  );

  factory MaintenanceSchedule.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    return MaintenanceSchedule(
      enabled: m['enabled'] as bool? ?? false,
      dailyOpenTime: m['dailyOpenTime']?.toString() ?? '08:00',
      dailyCloseTime: m['dailyCloseTime']?.toString() ?? '22:00',
      weeklyHolidays: List<int>.from(m['weeklyHolidays'] ?? const []),
      emergencyClose: m['emergencyClose'] as bool? ?? false,
      autoReopen: m['autoReopen'] as bool? ?? true,
      festivalClosures: (m['festivalClosures'] as List<dynamic>? ?? [])
          .map(
            (e) => Map<String, String>.from(
              (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
            ),
          )
          .toList(),
    );
  }
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
  final LocalizedText highDemandMessage;

  static DriverSmartControl get defaultsInstance => DriverSmartControl(
    enabled: false,
    minDriversOnline: 2,
    autoPauseCod: false,
    limitOrderDistanceKm: 8,
    pauseOrdering: false,
    highDemandMessage: LocalizedText(en: 'High demand', te: '', hi: '', ar: ''),
  );

  factory DriverSmartControl.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaultsInstance;
    return DriverSmartControl(
      enabled: m['enabled'] as bool? ?? false,
      minDriversOnline: m['minDriversOnline'] as int? ?? 2,
      autoPauseCod: m['autoPauseCod'] as bool? ?? false,
      limitOrderDistanceKm:
          (m['limitOrderDistanceKm'] as num?)?.toDouble() ?? 8,
      pauseOrdering: m['pauseOrdering'] as bool? ?? false,
      highDemandMessage: LocalizedText.fromMap(m['highDemandMessage']),
    );
  }
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
}
