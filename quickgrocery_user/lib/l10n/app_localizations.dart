import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get add;

  /// No description provided for @addDeliveryTip.
  ///
  /// In en, this message translates to:
  /// **'Add delivery tip'**
  String get addDeliveryTip;

  /// No description provided for @addExtraTip.
  ///
  /// In en, this message translates to:
  /// **'Add extra tip'**
  String get addExtraTip;

  /// No description provided for @add_address.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get add_address;

  /// No description provided for @add_first_address.
  ///
  /// In en, this message translates to:
  /// **'Add your first address'**
  String get add_first_address;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @addresses_title.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get addresses_title;

  /// No description provided for @app_settings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get app_settings;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get app_version;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @apply_coupon.
  ///
  /// In en, this message translates to:
  /// **'APPLY COUPON'**
  String get apply_coupon;

  /// No description provided for @areaRequired.
  ///
  /// In en, this message translates to:
  /// **'Area or road name is required'**
  String get areaRequired;

  /// No description provided for @best_sellers.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get best_sellers;

  /// No description provided for @best_sellers_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Most loved products this week'**
  String get best_sellers_subtitle;

  /// No description provided for @big_deals_on_beauty_products.
  ///
  /// In en, this message translates to:
  /// **'Big deals on beauty products'**
  String get big_deals_on_beauty_products;

  /// No description provided for @billDetails.
  ///
  /// In en, this message translates to:
  /// **'Bill details'**
  String get billDetails;

  /// No description provided for @biometric_login.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometric_login;

  /// No description provided for @browsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browsing as Guest'**
  String get browsingAsGuest;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Continue with Mobile Number to place your order securely.'**
  String get loginRequiredMessage;

  /// No description provided for @guestProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestProfileTitle;

  /// No description provided for @guestProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to sync your orders and addresses.'**
  String get guestProfileSubtitle;

  /// No description provided for @guestOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your orders live here'**
  String get guestOrdersTitle;

  /// No description provided for @guestOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to view order history and track deliveries.'**
  String get guestOrdersSubtitle;

  /// No description provided for @saveGuestAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this address?'**
  String get saveGuestAddressTitle;

  /// No description provided for @saveGuestAddressMessage.
  ///
  /// In en, this message translates to:
  /// **'Save this address to your account?'**
  String get saveGuestAddressMessage;

  /// No description provided for @saveGuestAddressYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get saveGuestAddressYes;

  /// No description provided for @saveGuestAddressNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get saveGuestAddressNo;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// No description provided for @buy_groceries_easily.
  ///
  /// In en, this message translates to:
  /// **'Buy Groceries Easily\\nWith Us'**
  String get buy_groceries_easily;

  /// No description provided for @callDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Call delivery partner'**
  String get callDeliveryPartner;

  /// No description provided for @call_first.
  ///
  /// In en, this message translates to:
  /// **'Call 90242-83577 first.'**
  String get call_first;

  /// No description provided for @call_our_support.
  ///
  /// In en, this message translates to:
  /// **'Call Our Support Team'**
  String get call_our_support;

  /// No description provided for @call_support.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get call_support;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel order?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cancelled_orders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Orders'**
  String get cancelled_orders;

  /// No description provided for @cartClearedLocally.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared locally'**
  String get cartClearedLocally;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyMessage;

  /// No description provided for @cartSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Cart sync failed'**
  String get cartSyncFailed;

  /// No description provided for @cartUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cart unavailable'**
  String get cartUnavailable;

  /// No description provided for @cart_is_empty.
  ///
  /// In en, this message translates to:
  /// **'Cart Is Empty'**
  String get cart_is_empty;

  /// No description provided for @cashOnDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDeliveryLabel;

  /// No description provided for @cash_on_delivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cash_on_delivery;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categories_pill.
  ///
  /// In en, this message translates to:
  /// **'categories'**
  String get categories_pill;

  /// No description provided for @category_promo_video_title.
  ///
  /// In en, this message translates to:
  /// **'Spotlight offers'**
  String get category_promo_video_title;

  /// No description provided for @change_location.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get change_location;

  /// No description provided for @checking_service_availability.
  ///
  /// In en, this message translates to:
  /// **'Checking service availability...'**
  String get checking_service_availability;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @chooseDeliverySlot.
  ///
  /// In en, this message translates to:
  /// **'Choose a delivery slot'**
  String get chooseDeliverySlot;

  /// No description provided for @clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clear_cache;

  /// No description provided for @combo_added_to_cart.
  ///
  /// In en, this message translates to:
  /// **'Combo added to cart'**
  String get combo_added_to_cart;

  /// No description provided for @complete_profile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get complete_profile;

  /// No description provided for @confirm_location.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirm_location;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @completeAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Complete name, house, area & mobile to place order'**
  String get completeAddressDetails;

  /// No description provided for @continue_label.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_label;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @could_not_load_coupons.
  ///
  /// In en, this message translates to:
  /// **'Could not load coupons'**
  String get could_not_load_coupons;

  /// No description provided for @couponAppliedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied successfully'**
  String get couponAppliedSuccess;

  /// No description provided for @coupon_applied_checkout.
  ///
  /// In en, this message translates to:
  /// **'{code} applied — use at checkout'**
  String coupon_applied_checkout(String code);

  /// No description provided for @coupon_applied_prefix.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get coupon_applied_prefix;

  /// No description provided for @coupon_copied.
  ///
  /// In en, this message translates to:
  /// **'Coupon code {code} copied'**
  String coupon_copied(String code);

  /// No description provided for @coupon_discount.
  ///
  /// In en, this message translates to:
  /// **'Coupon Discount'**
  String get coupon_discount;

  /// No description provided for @coupon_section_title.
  ///
  /// In en, this message translates to:
  /// **'Offers & coupons'**
  String get coupon_section_title;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons;

  /// No description provided for @couponsAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Coupons & Offers'**
  String get couponsAndOffers;

  /// No description provided for @coupons_available.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String coupons_available(int count);

  /// No description provided for @curated_picks_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated picks for you'**
  String get curated_picks_subtitle;

  /// No description provided for @customTip.
  ///
  /// In en, this message translates to:
  /// **'Custom tip'**
  String get customTip;

  /// No description provided for @customerPhotos.
  ///
  /// In en, this message translates to:
  /// **'Customer photos'**
  String get customerPhotos;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete review?'**
  String get deleteReviewTitle;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_account_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account_title;

  /// No description provided for @delete_account_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent.\n\nThis action will permanently remove your account, saved addresses, cart, profile information and other personal data.\n\nThis action cannot be undone.'**
  String get delete_account_confirmation;

  /// No description provided for @delete_account_warning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get delete_account_warning;

  /// No description provided for @delete_account_success.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get delete_account_success;

  /// No description provided for @delete_account_failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get delete_account_failed;

  /// No description provided for @delete_account_reauth_title.
  ///
  /// In en, this message translates to:
  /// **'Verify it\'s you'**
  String get delete_account_reauth_title;

  /// No description provided for @delete_account_reauth_message.
  ///
  /// In en, this message translates to:
  /// **'For security, enter the OTP sent to your phone to confirm account deletion.'**
  String get delete_account_reauth_message;

  /// No description provided for @delete_account_reauth_send_otp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get delete_account_reauth_send_otp;

  /// No description provided for @delete_account_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get delete_account_in_progress;

  /// No description provided for @delete_account_network_error.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get delete_account_network_error;

  /// No description provided for @delete_account_permission_error.
  ///
  /// In en, this message translates to:
  /// **'Permission denied while deleting your data. Please contact support.'**
  String get delete_account_permission_error;

  /// No description provided for @delete_address_body.
  ///
  /// In en, this message translates to:
  /// **'This address will be deleted from your saved list.'**
  String get delete_address_body;

  /// No description provided for @delete_address_title.
  ///
  /// In en, this message translates to:
  /// **'Remove address?'**
  String get delete_address_title;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @delivered_orders.
  ///
  /// In en, this message translates to:
  /// **'Delivered Orders'**
  String get delivered_orders;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFeeLabel;

  /// No description provided for @deliveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Delivery unavailable for your location'**
  String get deliveryUnavailable;

  /// No description provided for @delivery_charge.
  ///
  /// In en, this message translates to:
  /// **'Delivery charge'**
  String get delivery_charge;

  /// No description provided for @delivery_eta_title.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery'**
  String get delivery_eta_title;

  /// No description provided for @delivery_in_20_minutes.
  ///
  /// In en, this message translates to:
  /// **'Delivery in 20 minutes'**
  String get delivery_in_20_minutes;

  /// No description provided for @delivery_notifications.
  ///
  /// In en, this message translates to:
  /// **'Delivery Notifications'**
  String get delivery_notifications;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @dont_receive_otp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t receive the OTP?'**
  String get dont_receive_otp;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddress;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address.'**
  String get emailRequired;

  /// No description provided for @email_support.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get email_support;

  /// No description provided for @empty_checkout_address_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address to see slots, payment options, and your bill summary.'**
  String get empty_checkout_address_subtitle;

  /// No description provided for @empty_checkout_address_title.
  ///
  /// In en, this message translates to:
  /// **'Where should we deliver?'**
  String get empty_checkout_address_title;

  /// No description provided for @enableLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationTitle;

  /// No description provided for @enterValidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter valid mobile number'**
  String get enterValidMobile;

  /// No description provided for @epic_price_drop_items.
  ///
  /// In en, this message translates to:
  /// **'Epic price drop items'**
  String get epic_price_drop_items;

  /// No description provided for @errorGoBackOrRestart.
  ///
  /// In en, this message translates to:
  /// **'Go back or restart the app.'**
  String get errorGoBackOrRestart;

  /// No description provided for @errorPartCouldNotBeShown.
  ///
  /// In en, this message translates to:
  /// **'This part of the app couldn\'t be shown.'**
  String get errorPartCouldNotBeShown;

  /// No description provided for @explore_cta.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore_cta;

  /// No description provided for @explore_products.
  ///
  /// In en, this message translates to:
  /// **'Explore Products'**
  String get explore_products;

  /// No description provided for @failedToLoadCart.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your cart'**
  String get failedToLoadCart;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @featured_for_you.
  ///
  /// In en, this message translates to:
  /// **'Featured For You'**
  String get featured_for_you;

  /// No description provided for @featured_this_week.
  ///
  /// In en, this message translates to:
  /// **'Featured this week'**
  String get featured_this_week;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @flash_deals_title.
  ///
  /// In en, this message translates to:
  /// **'Flash deals'**
  String get flash_deals_title;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @freeUpper.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get freeUpper;

  /// No description provided for @free_delivery_above_99.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery on Orders Above 99rs'**
  String get free_delivery_above_99;

  /// No description provided for @fresh_groceries_delivered.
  ///
  /// In en, this message translates to:
  /// **'Fresh groceries delivered fast\\nWith the best deals in town'**
  String get fresh_groceries_delivered;

  /// No description provided for @friend_gets.
  ///
  /// In en, this message translates to:
  /// **'Friend Gets'**
  String get friend_gets;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get full_name;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get good_afternoon;

  /// No description provided for @good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get good_evening;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get good_morning;

  /// No description provided for @grand_total.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grand_total;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get home;

  /// No description provided for @house_no_building.
  ///
  /// In en, this message translates to:
  /// **'House No. Building Name'**
  String get house_no_building;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @incorrect_otp.
  ///
  /// In en, this message translates to:
  /// **'Incorrect OTP'**
  String get incorrect_otp;

  /// No description provided for @invalid_otp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalid_otp;

  /// No description provided for @invite_friends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get invite_friends;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Item} other{{count} Items}}'**
  String itemLabel(num count);

  /// No description provided for @itemOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'This item is out of stock'**
  String get itemOutOfStock;

  /// No description provided for @itemTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Item total'**
  String get itemTotalLabel;

  /// No description provided for @item_added_to_cart.
  ///
  /// In en, this message translates to:
  /// **'Item added to cart'**
  String get item_added_to_cart;

  /// No description provided for @item_details.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get item_details;

  /// No description provided for @item_total.
  ///
  /// In en, this message translates to:
  /// **'Item Total'**
  String get item_total;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get items;

  /// No description provided for @items_in_category.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String items_in_category(int count);

  /// No description provided for @joinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedStatus;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @leaveReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get leaveReviewTitle;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @live_order_tracking.
  ///
  /// In en, this message translates to:
  /// **'Live Order Tracking'**
  String get live_order_tracking;

  /// No description provided for @location_permission_body.
  ///
  /// In en, this message translates to:
  /// **'Allow location access so we can move the map to where you are. You can still search manually.'**
  String get location_permission_body;

  /// No description provided for @location_permission_needed.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get location_permission_needed;

  /// No description provided for @location_services_off.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off'**
  String get location_services_off;

  /// No description provided for @location_services_off_body.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS to center the map on your device, or search for your address above.'**
  String get location_services_off_body;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @maintenance_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get maintenance_coming_soon;

  /// No description provided for @maintenance_coming_soon_hint.
  ///
  /// In en, this message translates to:
  /// **'New products launching soon'**
  String get maintenance_coming_soon_hint;

  /// No description provided for @maintenance_contact_support.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get maintenance_contact_support;

  /// No description provided for @maintenance_coupons.
  ///
  /// In en, this message translates to:
  /// **'Save with these codes'**
  String get maintenance_coupons;

  /// No description provided for @maintenance_hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get maintenance_hours;

  /// No description provided for @maintenance_minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get maintenance_minutes;

  /// No description provided for @maintenance_offers_hint.
  ///
  /// In en, this message translates to:
  /// **'Exclusive offers when we reopen'**
  String get maintenance_offers_hint;

  /// No description provided for @maintenance_offline.
  ///
  /// In en, this message translates to:
  /// **'No internet — we\'ll refresh when you\'re back online'**
  String get maintenance_offline;

  /// No description provided for @maintenance_referral.
  ///
  /// In en, this message translates to:
  /// **'Refer & earn'**
  String get maintenance_referral;

  /// No description provided for @maintenance_referral_hint.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and earn rewards'**
  String get maintenance_referral_hint;

  /// No description provided for @maintenance_reopens_in.
  ///
  /// In en, this message translates to:
  /// **'Reopens in'**
  String get maintenance_reopens_in;

  /// No description provided for @maintenance_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get maintenance_retry;

  /// No description provided for @maintenance_seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get maintenance_seconds;

  /// No description provided for @maintenance_while_you_wait.
  ///
  /// In en, this message translates to:
  /// **'While you wait'**
  String get maintenance_while_you_wait;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @manage_arrow.
  ///
  /// In en, this message translates to:
  /// **'Manage →'**
  String get manage_arrow;

  /// No description provided for @mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get mark_all_read;

  /// No description provided for @maxOrderLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum order limit reached'**
  String get maxOrderLimitReached;

  /// No description provided for @missed_calls.
  ///
  /// In en, this message translates to:
  /// **'Missed calls will not be returned.'**
  String get missed_calls;

  /// No description provided for @mobile_number.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobile_number;

  /// No description provided for @move_map_hint.
  ///
  /// In en, this message translates to:
  /// **'Move the map to place the pin — address updates automatically'**
  String get move_map_hint;

  /// No description provided for @mrp.
  ///
  /// In en, this message translates to:
  /// **'MRP'**
  String get mrp;

  /// No description provided for @mrpTotal.
  ///
  /// In en, this message translates to:
  /// **'MRP Total'**
  String get mrpTotal;

  /// No description provided for @my_address.
  ///
  /// In en, this message translates to:
  /// **'My Address'**
  String get my_address;

  /// No description provided for @my_bag.
  ///
  /// In en, this message translates to:
  /// **'My Bag'**
  String get my_bag;

  /// No description provided for @my_orders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get my_orders;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nav_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get nav_categories;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get nav_orders;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No Orders Found!'**
  String get noOrdersFound;

  /// No description provided for @no_coupons_available.
  ///
  /// In en, this message translates to:
  /// **'No coupons available'**
  String get no_coupons_available;

  /// No description provided for @no_filtered_products.
  ///
  /// In en, this message translates to:
  /// **'No filteredProductsList Found'**
  String get no_filtered_products;

  /// No description provided for @no_products_found.
  ///
  /// In en, this message translates to:
  /// **'No Products Found'**
  String get no_products_found;

  /// No description provided for @no_saved_coupons.
  ///
  /// In en, this message translates to:
  /// **'No saved coupons available'**
  String get no_saved_coupons;

  /// No description provided for @non_urgent_email.
  ///
  /// In en, this message translates to:
  /// **'For non-urgent issues, use email.'**
  String get non_urgent_email;

  /// No description provided for @notification_center.
  ///
  /// In en, this message translates to:
  /// **'Notification center'**
  String get notification_center;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @offers_discounts.
  ///
  /// In en, this message translates to:
  /// **'Offers & Discounts'**
  String get offers_discounts;

  /// No description provided for @offers_for_you.
  ///
  /// In en, this message translates to:
  /// **'Offers for you'**
  String get offers_for_you;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'OFFICE'**
  String get office;

  /// No description provided for @onlinePaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Online Payment'**
  String get onlinePaymentLabel;

  /// No description provided for @online_payment.
  ///
  /// In en, this message translates to:
  /// **'Online payment'**
  String get online_payment;

  /// No description provided for @onlyNItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only {count} items available'**
  String onlyNItemsAvailable(int count);

  /// No description provided for @onlyOneItemAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only 1 item available'**
  String get onlyOneItemAvailable;

  /// No description provided for @open_app_settings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get open_app_settings;

  /// No description provided for @open_location_settings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get open_location_settings;

  /// No description provided for @orderCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled by you!'**
  String get orderCancelledByYou;

  /// No description provided for @order_updates.
  ///
  /// In en, this message translates to:
  /// **'Order Updates'**
  String get order_updates;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @other_label.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other_label;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'OUT OF STOCK'**
  String get outOfStock;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters required'**
  String get passwordMinLength;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @pcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get pcs;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @pending_orders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pending_orders;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @pick_address_short.
  ///
  /// In en, this message translates to:
  /// **'Set delivery address'**
  String get pick_address_short;

  /// No description provided for @pick_on_map.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pick_on_map;

  /// No description provided for @picked_for_you.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get picked_for_you;

  /// No description provided for @place_order.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get place_order;

  /// No description provided for @platform_fee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platform_fee;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get pleaseSelectGender;

  /// No description provided for @please_add_address.
  ///
  /// In en, this message translates to:
  /// **'Please ADD address'**
  String get please_add_address;

  /// No description provided for @please_enter_valid_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid phone number'**
  String get please_enter_valid_phone;

  /// No description provided for @please_type_verification_code.
  ///
  /// In en, this message translates to:
  /// **'Please type the verification code sent'**
  String get please_type_verification_code;

  /// No description provided for @please_wait.
  ///
  /// In en, this message translates to:
  /// **'Please Wait..'**
  String get please_wait;

  /// No description provided for @popular_near_you.
  ///
  /// In en, this message translates to:
  /// **'Popular near you'**
  String get popular_near_you;

  /// No description provided for @popular_near_you_sub.
  ///
  /// In en, this message translates to:
  /// **'What others are stocking up on'**
  String get popular_near_you_sub;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @productDiscount.
  ///
  /// In en, this message translates to:
  /// **'Product Discount'**
  String get productDiscount;

  /// No description provided for @product_added_favorite.
  ///
  /// In en, this message translates to:
  /// **'product added to favorite'**
  String get product_added_favorite;

  /// No description provided for @product_alerts.
  ///
  /// In en, this message translates to:
  /// **'Product Alerts'**
  String get product_alerts;

  /// No description provided for @product_removed_favorite.
  ///
  /// In en, this message translates to:
  /// **'product removed from favorite'**
  String get product_removed_favorite;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @promo_more_soon.
  ///
  /// In en, this message translates to:
  /// **'Offer link coming soon — check the home page for deals.'**
  String get promo_more_soon;

  /// No description provided for @promotional_messages.
  ///
  /// In en, this message translates to:
  /// **'Promotional Messages'**
  String get promotional_messages;

  /// No description provided for @push_notifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get push_notifications;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty:'**
  String get qtyLabel;

  /// No description provided for @quickGrocery.
  ///
  /// In en, this message translates to:
  /// **'QUICK GROCERY'**
  String get quickGrocery;

  /// No description provided for @quick_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get quick_address;

  /// No description provided for @quick_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get quick_orders;

  /// No description provided for @quick_wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get quick_wishlist;

  /// No description provided for @rateDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rate Delivery'**
  String get rateDelivery;

  /// No description provided for @ratingsAndReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsAndReviews;

  /// No description provided for @recommended_products.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommended_products;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referralCodeCopied;

  /// No description provided for @referral_copied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referral_copied;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resend_otp_in.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resend_otp_in(int seconds);

  /// No description provided for @retryBanners.
  ///
  /// In en, this message translates to:
  /// **'Retry banners'**
  String get retryBanners;

  /// No description provided for @retry_location.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry_location;

  /// No description provided for @returned_orders.
  ///
  /// In en, this message translates to:
  /// **'Returned Orders'**
  String get returned_orders;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @rewardGranted.
  ///
  /// In en, this message translates to:
  /// **'Reward Granted'**
  String get rewardGranted;

  /// No description provided for @road_name_area.
  ///
  /// In en, this message translates to:
  /// **'Road Name,Area,Colony'**
  String get road_name_area;

  /// No description provided for @save_address.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get save_address;

  /// No description provided for @save_address_button.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get save_address_button;

  /// No description provided for @saved_addresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get saved_addresses;

  /// No description provided for @saved_coupons.
  ///
  /// In en, this message translates to:
  /// **'Saved Coupons'**
  String get saved_coupons;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @search_delivery_location_hint.
  ///
  /// In en, this message translates to:
  /// **'Search area, street, landmark…'**
  String get search_delivery_location_hint;

  /// No description provided for @search_hint_bread.
  ///
  /// In en, this message translates to:
  /// **'Search \"bread\"'**
  String get search_hint_bread;

  /// No description provided for @search_hint_fruits.
  ///
  /// In en, this message translates to:
  /// **'Search \"fruits\"'**
  String get search_hint_fruits;

  /// No description provided for @search_hint_milk.
  ///
  /// In en, this message translates to:
  /// **'Search \"milk\"'**
  String get search_hint_milk;

  /// No description provided for @search_hint_snacks.
  ///
  /// In en, this message translates to:
  /// **'Search \"snacks\"'**
  String get search_hint_snacks;

  /// No description provided for @search_products.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get search_products;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get see_all;

  /// No description provided for @select_delivery_location.
  ///
  /// In en, this message translates to:
  /// **'Select delivery location'**
  String get select_delivery_location;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @service_not_available.
  ///
  /// In en, this message translates to:
  /// **'Service Not Available'**
  String get service_not_available;

  /// No description provided for @service_not_available_message.
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry, but we don\'t currently deliver to your location. Please select a different delivery address or check back later as we expand our service areas.'**
  String get service_not_available_message;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInvite;

  /// No description provided for @share_referral.
  ///
  /// In en, this message translates to:
  /// **'Share Referral'**
  String get share_referral;

  /// No description provided for @shop_by_category.
  ///
  /// In en, this message translates to:
  /// **'Shop By Category'**
  String get shop_by_category;

  /// No description provided for @shop_now_cta.
  ///
  /// In en, this message translates to:
  /// **'Shop now'**
  String get shop_now_cta;

  /// No description provided for @signInToFavorite.
  ///
  /// In en, this message translates to:
  /// **'Sign in required to favorite items.'**
  String get signInToFavorite;

  /// No description provided for @someItemsOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Some items are out of stock'**
  String get someItemsOutOfStock;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get something_went_wrong;

  /// No description provided for @sorry_minimum_order.
  ///
  /// In en, this message translates to:
  /// **'Sorry!. We are taking Delivery Orders above ₹{amount}'**
  String sorry_minimum_order(String amount);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// No description provided for @storeClosed.
  ///
  /// In en, this message translates to:
  /// **'Store is closed'**
  String get storeClosed;

  /// No description provided for @store_offline_message.
  ///
  /// In en, this message translates to:
  /// **'Our store is currently offline. Please check back soon—we\'ll be back to serve you shortly!'**
  String get store_offline_message;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @support_available.
  ///
  /// In en, this message translates to:
  /// **'Support is available daily from 9:00 AM to 6:30 PM.'**
  String get support_available;

  /// No description provided for @support_call_conditions.
  ///
  /// In en, this message translates to:
  /// **'Support Call Conditions'**
  String get support_call_conditions;

  /// No description provided for @support_mail.
  ///
  /// In en, this message translates to:
  /// **'Support Mail'**
  String get support_mail;

  /// No description provided for @support_number.
  ///
  /// In en, this message translates to:
  /// **'Support {number}'**
  String support_number(String number);

  /// No description provided for @tap_to_apply_coupon.
  ///
  /// In en, this message translates to:
  /// **'Tap to apply a coupon'**
  String get tap_to_apply_coupon;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYou;

  /// No description provided for @thisItemOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'This item is out of stock'**
  String get thisItemOutOfStock;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @today_snacks_deals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s snacks deals'**
  String get today_snacks_deals;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Items:'**
  String get totalItemsLabel;

  /// No description provided for @totalUpper.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalUpper;

  /// No description provided for @track_order.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get track_order;

  /// No description provided for @trending_categories.
  ///
  /// In en, this message translates to:
  /// **'Trending categories'**
  String get trending_categories;

  /// No description provided for @trending_now.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trending_now;

  /// No description provided for @trending_subtitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s selling fast today'**
  String get trending_subtitle;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available. Please update to continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredTitle;

  /// No description provided for @updating_address.
  ///
  /// In en, this message translates to:
  /// **'Updating address…'**
  String get updating_address;

  /// No description provided for @upiLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upiLabel;

  /// No description provided for @use_current_location.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get use_current_location;

  /// No description provided for @view_all_arrow.
  ///
  /// In en, this message translates to:
  /// **'View All →'**
  String get view_all_arrow;

  /// No description provided for @view_cart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get view_cart;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @we_are_closed.
  ///
  /// In en, this message translates to:
  /// **'We are closed!'**
  String get we_are_closed;

  /// No description provided for @whatsapp_support.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Support'**
  String get whatsapp_support;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in wishlist'**
  String get wishlistEmpty;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get writeReview;

  /// No description provided for @you_earn.
  ///
  /// In en, this message translates to:
  /// **'You Earn'**
  String get you_earn;

  /// No description provided for @you_might_also_like.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get you_might_also_like;

  /// No description provided for @your_mobile_number.
  ///
  /// In en, this message translates to:
  /// **'your mobile number'**
  String get your_mobile_number;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @deleteReviewBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteReviewBody;

  /// No description provided for @failedToLoadReviews.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews'**
  String get failedToLoadReviews;

  /// No description provided for @noReviewsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No reviews match this filter'**
  String get noReviewsMatchFilter;

  /// No description provided for @helpfulCount.
  ///
  /// In en, this message translates to:
  /// **'Helpful ({count})'**
  String helpfulCount(int count);

  /// No description provided for @speechRecognitionError.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition error: {error}'**
  String speechRecognitionError(String error);

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice search'**
  String get microphonePermissionRequired;

  /// No description provided for @speechRecognitionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device'**
  String get speechRecognitionUnavailable;

  /// No description provided for @signInForNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see notifications'**
  String get signInForNotifications;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @couldNotSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile: {error}'**
  String couldNotSaveProfile(String error);

  /// No description provided for @orderSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Order support'**
  String get orderSupportTitle;

  /// No description provided for @itemsNotAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'None of these items are available right now'**
  String get itemsNotAvailableNow;

  /// No description provided for @couldNotGenerateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Could not generate invoice: {error}'**
  String couldNotGenerateInvoice(String error);

  /// No description provided for @deliveryPartnerNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Delivery partner not assigned yet'**
  String get deliveryPartnerNotAssigned;

  /// No description provided for @couldNotLoadOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not load order details'**
  String get couldNotLoadOrder;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @liveStatus.
  ///
  /// In en, this message translates to:
  /// **'Live status'**
  String get liveStatus;

  /// No description provided for @rateDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Rate delivery partner'**
  String get rateDeliveryPartner;

  /// No description provided for @rateVendor.
  ///
  /// In en, this message translates to:
  /// **'Rate vendor'**
  String get rateVendor;

  /// No description provided for @noOrdersFoundPeriod.
  ///
  /// In en, this message translates to:
  /// **'No orders found.'**
  String get noOrdersFoundPeriod;

  /// No description provided for @noCancelledOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No Cancelled Orders Found!'**
  String get noCancelledOrdersFound;

  /// No description provided for @cancelOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrderButton;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @reviewDeleted.
  ///
  /// In en, this message translates to:
  /// **'Review deleted'**
  String get reviewDeleted;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get editReview;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeAReview;

  /// No description provided for @reviewsEditWindow.
  ///
  /// In en, this message translates to:
  /// **'Reviews can only be edited within 24 hours'**
  String get reviewsEditWindow;

  /// No description provided for @pleaseWriteReviewMinChars.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 10 characters'**
  String get pleaseWriteReviewMinChars;

  /// No description provided for @reviewSubmittedPending.
  ///
  /// In en, this message translates to:
  /// **'Review submitted! It will appear after approval.'**
  String get reviewSubmittedPending;

  /// No description provided for @addPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'Add photos ({count}/6)'**
  String addPhotosCount(int count);

  /// No description provided for @productQuality.
  ///
  /// In en, this message translates to:
  /// **'Product Quality'**
  String get productQuality;

  /// No description provided for @freshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get freshness;

  /// No description provided for @packaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get packaging;

  /// No description provided for @deliveryExperience.
  ///
  /// In en, this message translates to:
  /// **'Delivery Experience'**
  String get deliveryExperience;

  /// No description provided for @valueForMoney.
  ///
  /// In en, this message translates to:
  /// **'Value for Money'**
  String get valueForMoney;

  /// No description provided for @yourReview.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get yourReview;

  /// No description provided for @verifiedPurchase.
  ///
  /// In en, this message translates to:
  /// **'Verified Purchase'**
  String get verifiedPurchase;

  /// No description provided for @sellerReply.
  ///
  /// In en, this message translates to:
  /// **'Seller reply'**
  String get sellerReply;

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar products'**
  String get similarProducts;

  /// No description provided for @couldNotLoadSimilarProducts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load similar products'**
  String get couldNotLoadSimilarProducts;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewed;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @inviteMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite message copied'**
  String get inviteMessageCopied;

  /// No description provided for @appDownloadLinkNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'App download link not configured by Admin'**
  String get appDownloadLinkNotConfigured;

  /// No description provided for @nav_offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get nav_offers;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @myReferralCode.
  ///
  /// In en, this message translates to:
  /// **'My Referral Code'**
  String get myReferralCode;

  /// No description provided for @referralRewards.
  ///
  /// In en, this message translates to:
  /// **'Referral rewards'**
  String get referralRewards;

  /// No description provided for @referralStats.
  ///
  /// In en, this message translates to:
  /// **'Your referral stats'**
  String get referralStats;

  /// No description provided for @invitedFriends.
  ///
  /// In en, this message translates to:
  /// **'Invited Friends'**
  String get invitedFriends;

  /// No description provided for @ordered.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get ordered;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @referralComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Referral Program Coming Soon'**
  String get referralComingSoon;

  /// No description provided for @referralUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Referral system unavailable'**
  String get referralUnavailable;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help'**
  String get needHelp;

  /// No description provided for @yourRider.
  ///
  /// In en, this message translates to:
  /// **'Your rider'**
  String get yourRider;

  /// No description provided for @riderSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for delivery partner…'**
  String get riderSearching;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order delivered!'**
  String get orderDelivered;

  /// No description provided for @shareExperienceOptional.
  ///
  /// In en, this message translates to:
  /// **'Share your experience (optional)'**
  String get shareExperienceOptional;

  /// No description provided for @clearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get clearCartTitle;

  /// No description provided for @clearCartBody.
  ///
  /// In en, this message translates to:
  /// **'All items will be removed from your bag.'**
  String get clearCartBody;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @itemsInBag.
  ///
  /// In en, this message translates to:
  /// **'Items in bag'**
  String get itemsInBag;

  /// No description provided for @freeDeliveryUnlocked.
  ///
  /// In en, this message translates to:
  /// **'FREE delivery unlocked'**
  String get freeDeliveryUnlocked;

  /// No description provided for @removedUnavailableItems.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} unavailable items'**
  String removedUnavailableItems(int count);

  /// No description provided for @removeUnavailableToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Some items are unavailable. Remove them to continue checkout.'**
  String get removeUnavailableToCheckout;

  /// No description provided for @someItemsUnavailableInBag.
  ///
  /// In en, this message translates to:
  /// **'Some items in your bag are unavailable — remove them to checkout'**
  String get someItemsUnavailableInBag;

  /// No description provided for @enterCouponCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Coupon Code'**
  String get enterCouponCodeTitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @couponAppliedCheck.
  ///
  /// In en, this message translates to:
  /// **'Coupon Applied ✅'**
  String get couponAppliedCheck;

  /// No description provided for @youSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved ₹{amount}'**
  String youSaved(String amount);

  /// No description provided for @bestCouponAvailable.
  ///
  /// In en, this message translates to:
  /// **'Best Coupon Available'**
  String get bestCouponAvailable;

  /// No description provided for @noEligibleCoupons.
  ///
  /// In en, this message translates to:
  /// **'No eligible coupons for this cart'**
  String get noEligibleCoupons;

  /// No description provided for @thankDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Thank Your Delivery Partner'**
  String get thankDeliveryPartner;

  /// No description provided for @addTipDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a tip to appreciate your delivery partner'**
  String get addTipDescription;

  /// No description provided for @updatingTip.
  ///
  /// In en, this message translates to:
  /// **'Updating tip…'**
  String get updatingTip;

  /// No description provided for @tipThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you! ₹{amount} tip added successfully.'**
  String tipThankYou(String amount);

  /// No description provided for @maxTip.
  ///
  /// In en, this message translates to:
  /// **'Maximum tip is ₹{amount}'**
  String maxTip(String amount);

  /// No description provided for @paymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed.'**
  String get paymentNotCompleted;

  /// No description provided for @couldNotUpdateTip.
  ///
  /// In en, this message translates to:
  /// **'Could not update tip. Please try again.'**
  String get couldNotUpdateTip;

  /// No description provided for @howWasDelivery.
  ///
  /// In en, this message translates to:
  /// **'How was your delivery?'**
  String get howWasDelivery;

  /// No description provided for @orderSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Order successful'**
  String get orderSuccessful;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @visitAgain.
  ///
  /// In en, this message translates to:
  /// **'Visit again'**
  String get visitAgain;

  /// No description provided for @noOrdersHereYet.
  ///
  /// In en, this message translates to:
  /// **'No orders here yet'**
  String get noOrdersHereYet;

  /// No description provided for @couldNotLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Could not load orders'**
  String get couldNotLoadOrders;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @notPaid.
  ///
  /// In en, this message translates to:
  /// **'Not Paid'**
  String get notPaid;

  /// No description provided for @deliveryChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery: ₹{amount}'**
  String deliveryChargeLabel(String amount);

  /// No description provided for @fastDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fast delivery'**
  String get fastDelivery;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'payments'**
  String get payments;

  /// No description provided for @noExchangeOrReturn.
  ///
  /// In en, this message translates to:
  /// **'No exchange or return'**
  String get noExchangeOrReturn;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @couldNotLoadReviewsShort.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reviews.'**
  String get couldNotLoadReviewsShort;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start shopping'**
  String get startShopping;

  /// No description provided for @startExploringGroceries.
  ///
  /// In en, this message translates to:
  /// **'Start exploring fresh groceries!'**
  String get startExploringGroceries;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @withPhotos.
  ///
  /// In en, this message translates to:
  /// **'With photos'**
  String get withPhotos;

  /// No description provided for @addTipAmount.
  ///
  /// In en, this message translates to:
  /// **'Add ₹{amount}'**
  String addTipAmount(String amount);

  /// No description provided for @failedToRemoveProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove product'**
  String get failedToRemoveProduct;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message…'**
  String get typeMessageHint;

  /// No description provided for @needHelpWithOrder.
  ///
  /// In en, this message translates to:
  /// **'Need help with this order?'**
  String get needHelpWithOrder;

  /// No description provided for @addedItemsToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {count} items to your cart'**
  String addedItemsToCart(int count);

  /// No description provided for @trackOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrderTitle;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @firstOrderOffer.
  ///
  /// In en, this message translates to:
  /// **'First Order Offer'**
  String get firstOrderOffer;

  /// No description provided for @moreOffers.
  ///
  /// In en, this message translates to:
  /// **'More offers'**
  String get moreOffers;

  /// No description provided for @firstOrder.
  ///
  /// In en, this message translates to:
  /// **'1st ORDER'**
  String get firstOrder;

  /// No description provided for @minOrder.
  ///
  /// In en, this message translates to:
  /// **'Min order ₹{amount}'**
  String minOrder(String amount);

  /// No description provided for @eligibleTapToApply.
  ///
  /// In en, this message translates to:
  /// **'Eligible · Tap to apply'**
  String get eligibleTapToApply;

  /// No description provided for @availableCoupons.
  ///
  /// In en, this message translates to:
  /// **'Available Coupons'**
  String get availableCoupons;

  /// No description provided for @noCouponsAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'No coupons available right now'**
  String get noCouponsAvailableNow;

  /// No description provided for @cancelOrderAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderAction;

  /// No description provided for @clearCartAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCartAction;

  /// No description provided for @noCouponsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No coupons right now'**
  String get noCouponsRightNow;

  /// No description provided for @enterCouponCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get enterCouponCodeHint;

  /// No description provided for @partner_with_us.
  ///
  /// In en, this message translates to:
  /// **'Partner with us'**
  String get partner_with_us;

  /// No description provided for @become_store_partner.
  ///
  /// In en, this message translates to:
  /// **'Become a store partner'**
  String get become_store_partner;

  /// No description provided for @partner_with_us_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Quick Groceries as a store or delivery partner'**
  String get partner_with_us_subtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
