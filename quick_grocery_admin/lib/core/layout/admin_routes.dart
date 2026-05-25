/// Stable route ids for admin navigation.
abstract final class AdminRoutes {
  static const dashboard = 'Dashboard';

  // User management (simplified)
  static const customersAll = 'All Customers';
  static const customersActive = 'Active Users';
  static const customersBlocked = 'Blocked Users';
  static const customersNew = 'New Users';

  /// Legacy alias
  static const userList = customersAll;

  static const customerRoutes = <String>[
    customersAll,
    customersActive,
    customersBlocked,
    customersNew,
  ];

  static const vendorAdd = 'Vendor Add';
  static const vendorList = 'Vendor List';
  static const vendorRequests = 'Vendor Requests';

  // Orders module
  static const ordersOverview = 'Overview';
  static const newOrders = 'New Orders';
  static const manageOrders = 'Manage Orders';
  static const refundRequests = 'Refund Requests';

  static const addDeliveryBoy = 'Add Delivery Boy';
  static const deliveryBoyList = 'Delivery Boy List';
  static const deliveryZones = 'Delivery Zones';
  static const deliverySettings = 'Delivery Settings';
  static const productList = 'Product List';
  static const addCategory = 'Add Category';
  static const addSubcategory = 'Add Subcategory';
  static const addProducts = 'Add Products';
  static const reviewManagement = 'Review Management';
  static const reviewAnalytics = 'Review Analytics';
  static const addBanner = 'Add Banner';
  static const addCoupon = 'Add Coupon';
  static const comboOffers = 'Combo Offers';
  static const platformFee = 'Platform Fee & Charges';
  static const pushNotifications = 'Push Notifications';
  static const notificationTemplates = 'Notification Templates';
  static const notificationHistory = 'Notification History';
  static const appContent = 'App Content';
  static const supportSettings = 'Support Settings';
  static const maintenance = 'Maintenance & Availability';

  static const all = <String>[
    dashboard,
    ...customerRoutes,
    vendorAdd,
    vendorList,
    vendorRequests,
    ordersOverview,
    newOrders,
    manageOrders,
    refundRequests,
    addDeliveryBoy,
    deliveryBoyList,
    deliveryZones,
    deliverySettings,
    productList,
    addCategory,
    addSubcategory,
    addProducts,
    reviewManagement,
    reviewAnalytics,
    addBanner,
    addCoupon,
    comboOffers,
    platformFee,
    pushNotifications,
    notificationTemplates,
    notificationHistory,
    appContent,
    supportSettings,
    maintenance,
  ];
}
