import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/availability/availability_service.dart';
import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/user/checkout_preferences_store.dart';
import 'package:quickgrocery/view/address/screens/add_address_screen.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/domain/pricing_calculator.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/checkout_controller.dart';
import 'package:quickgrocery/view/cart/presentation/providers/delivery_slots_provider.dart';
import 'package:quickgrocery/view/cart/presentation/providers/order_repository_provider.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/delivery_instructions_field.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/delivery_slot_selector.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/payment_method_selector.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_checkout_bar.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_bill_card.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/checkout/widgets/address_card.dart';
import 'package:quickgrocery/view/checkout/widgets/empty_address_widget.dart';
import 'package:quickgrocery/core/device/device_id_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/checkout_coupon_section.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/checkout_tip_section.dart';
import 'package:quickgrocery/view/delivery_tips/models/delivery_tip_settings.dart';
import 'package:quickgrocery/view/delivery_tips/services/delivery_tip_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_extensions.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const _calc = PricingCalculator();
  final _tipService = deliveryTipServiceProvider;
  DeliveryTipSettings _tipSettings = DeliveryTipSettings.defaults();
  bool _tipSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTipSettings();
  }

  Future<void> _loadTipSettings() async {
    try {
      final s = await _tipService.fetchSettings();
      if (mounted) {
        setState(() {
          _tipSettings = s;
          _tipSettingsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tipSettingsLoaded = true);
    }
  }

  BillBreakdown _bill(CartState cart, double zoneCharge, {double tip = 0}) {
    final deliveryInt = zoneCharge > 0
        ? zoneCharge.round()
        : cart.pricing.standardDeliveryCharge;
    return _calc.compute(
      items: cart.items,
      config: cart.pricing,
      coupon: cart.coupon,
      deliveryChargeOverride: deliveryInt,
    ).withDeliveryTip(tip);
  }

  Future<void> _openAddAddress({AddressModel? edit}) async {
    final ok = await Navigator.push<bool>(
      context,
      AppPageRoutes.addAddress(editing: edit),
    );
    if (ok == true && mounted) {
      await legacy_provider.Provider.of<AddressService>(
        context,
        listen: false,
      ).getAddress();
    }
  }

  Future<void> _placeOrder({
    required CartState cart,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    required AddressModel address,
    required String pin,
    required LatLng coords,
    required String readableAddress,
  }) async {
    final checkoutNotifier = ref.read(checkoutControllerProvider.notifier);
    final cartNotifier = ref.read(cartProvider.notifier);
    final payment = legacy_provider.Provider.of<PaymentService>(
      context,
      listen: false,
    );

    try {
      final availability = await ref
          .read(availabilityServiceProvider)
          .check(cartItems: cart.items, address: address, pin: pin);
      availability.debugLog();

      final availabilityError = availability.blockingReason;
      if (availabilityError != null) {
        throw StateError(availabilityError);
      }

      checkoutNotifier.setPlacingOrder(true);

      final zoneCharge = availability.deliveryCharge;
      final tip = ref.read(checkoutControllerProvider).deliveryTipAmount;
      final bill = _bill(cart, zoneCharge, tip: tip);

      debugPrint(
        'ORDER PAYMENT: method=${paymentMethod.id} total=${bill.total} '
        'cod=${paymentMethod == PaymentMethod.cod}',
      );

      Future<void> finalize({String? paymentRef}) async {
        final orderId = await _createOrderWithFallback(
          cart: cart,
          bill: bill,
          address: address,
          readableAddress: readableAddress,
          coords: coords,
          slot: slot,
          instructions: instructions,
          paymentMethod: paymentMethod,
          paymentRef: paymentRef,
        );
        if (cart.coupon != null) {
          try {
            final deviceId = await DeviceIdService.getOrCreate();
            await ref
                .read(couponValidationClientProvider)
                .redeem(
                  code: cart.coupon!.code,
                  orderId: orderId,
                  subtotal: bill.subtotal,
                  discountApplied: bill.couponDiscount,
                  items: cart.items,
                  phone: address.mobile,
                  deviceId: deviceId,
                );
          } catch (e, stack) {
            debugPrint('COUPON REDEEM ERROR: $e');
            debugPrintStack(stackTrace: stack);
          }
        }
        await CheckoutPreferencesStore.recordSuccessfulOrder(
          orderId: orderId,
          state: ref.read(checkoutControllerProvider),
        );
        await cartNotifier.clear();
        checkoutNotifier.setPlacingOrder(false);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          AppPageRoutes.checkoutSuccess(orderId: orderId),
          (_) => false,
        );
      }

      if (paymentMethod == PaymentMethod.cod) {
        await finalize();
        return;
      }

      payment.openCheckout(
        bill.total,
        address.name,
        'Quick Grocery order',
        onPaymentSuccess: (paymentId) async {
          try {
            checkoutNotifier.setPlacingOrder(true);
            await finalize(paymentRef: paymentId);
          } catch (e, stack) {
            checkoutNotifier.setPlacingOrder(false);
            _showOrderError(e, stack);
          }
        },
      );
      checkoutNotifier.setPlacingOrder(false);
    } catch (e, stack) {
      checkoutNotifier.setPlacingOrder(false);
      _showOrderError(e, stack);
    }
  }

  void _showOrderError(Object e, StackTrace stack) {
    debugPrint('ORDER ERROR: $e');
    debugPrintStack(stackTrace: stack);
    String checkoutError(Object error) {
      if (error is FirebaseFunctionsException) {
        if (error.code == 'not-found') {
          return 'Order service unavailable. Please try again.';
        }
        if (error.code == 'unavailable') {
          return 'Order service is temporarily unavailable.';
        }
        if (error.code == 'permission-denied') {
          return 'Permission denied while creating order.';
        }
        return error.message ?? 'Failed to create order (${error.code})';
      }
      if (error is FirebaseException) {
        debugPrint(
          'ORDER FIREBASE ERROR code=${error.code} '
          'message=${error.message} plugin=${error.plugin}',
        );
        if (error.code == 'not-found') {
          return 'Required order data was not found.';
        }
        if (error.code == 'permission-denied') {
          return 'Permission denied while creating order.';
        }
        return error.message ?? 'Failed to create order (${error.code})';
      }
      return error.toString().replaceFirst('Bad state: ', '');
    }

    if (!mounted) return;
    showTopErrorToast(context, checkoutError(e));
  }

  Future<String> _createOrderWithFallback({
    required CartState cart,
    required BillBreakdown bill,
    required AddressModel address,
    required String readableAddress,
    required LatLng coords,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    String? paymentRef,
  }) async {
    try {
      return await ref
          .read(orderPlacementClientProvider)
          .placeOrder(
            items: cart.items,
            coupon: cart.coupon,
            bill: bill,
            address: address,
            currentAddressString: readableAddress,
            currentLatLng: coords,
            slot: slot,
            instructions: instructions,
            paymentMethod: paymentMethod,
            paymentRef: paymentRef,
            tipAmount: bill.deliveryPartnerTip,
          );
    } on FirebaseFunctionsException catch (e, stack) {
      debugPrint(
        'ORDER CALLABLE FAILED code=${e.code} message=${e.message} '
        'details=${e.details}',
      );
      debugPrintStack(stackTrace: stack);
      if (!_canFallbackToDirectOrder(e)) rethrow;
      return _createDirectFirestoreOrder(
        cart: cart,
        bill: bill,
        address: address,
        readableAddress: readableAddress,
        coords: coords,
        slot: slot,
        instructions: instructions,
        paymentMethod: paymentMethod,
        paymentRef: paymentRef,
      );
    }
  }

  bool _canFallbackToDirectOrder(FirebaseFunctionsException e) {
    return e.code == 'not-found' || e.code == 'unavailable';
  }

  Future<String> _createDirectFirestoreOrder({
    required CartState cart,
    required BillBreakdown bill,
    required AddressModel address,
    required String readableAddress,
    required LatLng coords,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    String? paymentRef,
  }) async {
    debugPrint(
      'ORDER FALLBACK: creating direct Firestore order path=orders '
      'reason=callable_unavailable',
    );
    try {
      final orderId = await ref
          .read(orderRepositoryProvider)
          .placeOrder(
            items: cart.items,
            coupon: cart.coupon,
            bill: bill,
            address: address,
            currentAddressString: readableAddress,
            currentLatLng: coords,
            slot: slot,
            instructions: instructions,
            paymentMethod: paymentMethod,
            paymentRef: paymentRef,
          );
      debugPrint('ORDER FALLBACK SUCCESS firestorePath=orders/$orderId');
      return orderId;
    } on FirebaseException catch (e, stack) {
      debugPrint(
        'ORDER FALLBACK FIRESTORE ERROR path=orders '
        'code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      debugPrint('ORDER FALLBACK ERROR path=orders error=$e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final checkoutNotifier = ref.read(checkoutControllerProvider.notifier);

    final slots = ref.watch(deliverySlotsProvider);

    final addressService = legacy_provider.Provider.of<AddressService>(context);
    final home = legacy_provider.Provider.of<HomeProvider>(
      context,
      listen: false,
    );

    ref.listen<String?>(
      checkoutControllerProvider.select((s) => s.errorMessage),
      (_, msg) {
        if (msg != null) {
          showTopErrorToast(context, msg);
          ref.read(checkoutControllerProvider.notifier).clearError();
        }
      },
    );

    final addresses = addressService.addresses ?? const <AddressModel>[];
    final preferredIndex = addressService.hasValidatedServiceableAddress
        ? addressService.selectedIndex
        : checkout.selectedAddressIndex;
    final idx = preferredIndex.clamp(
      0,
      addresses.isEmpty ? 0 : addresses.length - 1,
    );
    final selectedAddr = addresses.isEmpty ? null : addresses[idx];

    final pin = addressService.pinCode;
    final coords = addressService.latLng ?? home.currentLatLng;
    final readable = addressService.address;
    final zoneAsync = ref.watch(zoneDeliveryProvider(pin));
    final zoneCharge = zoneAsync.value ?? 0;
    final bill = _bill(cart, zoneCharge, tip: checkout.deliveryTipAmount);

    final hasAddr = addresses.isNotEmpty && selectedAddr != null;
    final oos = cart.items.any((e) => e.isUnavailable);
    final canPay =
        hasAddr && bill.meetsMinimumOrder && !oos && checkout.slot != null;

    String? barHint() {
      if (!hasAddr) return 'please_add_address'.tr();
      if (oos) return 'Some items are out of stock';
      if (!bill.meetsMinimumOrder) {
        final delta = (bill.minimumOrderValue - bill.subtotal).clamp(
          0,
          double.infinity,
        );
        return 'Min order ₹${bill.minimumOrderValue.toStringAsFixed(0)} · '
            'Add ₹${delta.toStringAsFixed(0)} more';
      }
      if (checkout.slot == null) return 'Choose a delivery slot';
      return null;
    }

    return Scaffold(
      backgroundColor: AppSurface.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CheckoutHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: addresses.isEmpty
                  ? EmptyAddressWidget(onAddAddress: () => _openAddAddress())
                  : RefreshIndicator(
                      color: AppColor.primary,
                      onRefresh: () => addressService.getAddress(),
                      child: CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeInDown(
                                duration: const Duration(milliseconds: 320),
                                child: _DeliverToSection(
                                  addresses: addresses,
                                  selectedIndex: idx,
                                  onSelect: (i) {
                                    checkoutNotifier.selectAddress(i);
                                    addressService.selectAddress(i);
                                  },
                                  onAdd: () => _openAddAddress(),
                                  onEdit: (a) => _openAddAddress(edit: a),
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeInDown(
                                duration: const Duration(milliseconds: 320),
                                child: _DeliveryEtaCard(
                                  slot: checkout.slot ?? slots.firstOrNull,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeInUp(
                                delay: const Duration(milliseconds: 80),
                                child: CheckoutCouponSection(
                                  checkoutPhone: selectedAddr?.mobile,
                                  deliveryChargeOverride: zoneCharge > 0
                                      ? zoneCharge.round()
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                            sliver: SliverToBoxAdapter(
                              child: DeliveryInstructionsField(
                                value: checkout.instructions,
                                onChanged: checkoutNotifier.setInstructions,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                            sliver: SliverToBoxAdapter(
                              child: DeliverySlotSelector(
                                slots: slots,
                                selected: checkout.slot,
                                onChanged: checkoutNotifier.selectSlot,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                            sliver: SliverToBoxAdapter(
                              child: PaymentMethodSelector(
                                selected: checkout.paymentMethod,
                                onChanged: checkoutNotifier.selectPaymentMethod,
                              ),
                            ),
                          ),
                          if (zoneAsync.isLoading && zoneCharge == 0)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
                                child: LinearProgressIndicator(
                                  minHeight: 2,
                                  backgroundColor: AppSurface.subtle,
                                ),
                              ),
                            ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CheckoutDeliveryInfo(
                                    bill: bill,
                                    pricing: cart.pricing,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_tipSettingsLoaded && _tipSettings.enabled) ...[
                                    CheckoutTipSection(
                                      settings: _tipSettings,
                                      selectedAmount: checkout.deliveryTipAmount,
                                      onChanged: checkoutNotifier.setDeliveryTip,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  PremiumBillCard(
                                    bill: bill,
                                    pricing: cart.pricing,
                                    couponLabel: cart.coupon != null
                                        ? 'Coupon · ${cart.coupon!.code}'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: hasAddr
          ? StickyCheckoutBar(
              totalAmount: bill.total,
              itemCount: cart.totalUnits,
              savings: bill.totalSavings,
              buttonText: 'Place Order',
              helperText: barHint(),
              helperIsError:
                  !hasAddr ||
                  oos ||
                  !bill.meetsMinimumOrder ||
                  checkout.slot == null,
              enabled: canPay && !checkout.isPlacingOrder,
              isLoading: checkout.isPlacingOrder,
              onTap: () async {
                if (!bill.meetsMinimumOrder || oos || checkout.slot == null) {
                  return;
                }
                await _placeOrder(
                  cart: cart,
                  slot: checkout.slot,
                  instructions: checkout.instructions,
                  paymentMethod: checkout.paymentMethod,
                  address: selectedAddr,
                  pin: pin ?? '',
                  coords: coords,
                  readableAddress: readable,
                );
              },
            )
          : StickyCheckoutBar(
              totalAmount: bill.total,
              itemCount: cart.totalUnits,
              savings: bill.totalSavings,
              buttonText: 'Add Address',
              helperText: barHint(),
              helperIsError: true,
              enabled: !checkout.isPlacingOrder,
              isLoading: checkout.isPlacingOrder,
              onTap: () => _openAddAddress(),
            ),
    );
  }
}

class _CheckoutDeliveryInfo extends StatelessWidget {
  const _CheckoutDeliveryInfo({required this.bill, required this.pricing});

  final BillBreakdown bill;
  final PricingConfig pricing;

  @override
  Widget build(BuildContext context) {
    final msg = !pricing.isDeliveryChargesEnabled
        ? 'Delivery charges are currently disabled'
        : bill.isFreeDelivery
        ? '🎉 FREE delivery unlocked'
        : pricing.isFreeDeliveryEnabled
        ? 'Free delivery above ₹${pricing.freeDeliveryThreshold}'
        : 'Delivery fee ₹${bill.deliveryFee.toStringAsFixed(0)} applies';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppSurface.border),
      ),
      child: Text(
        msg,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppSurface.textSecondary,
        ),
      ),
    );
  }
}

extension _SlotListX on List<DeliverySlot> {
  DeliverySlot? get firstOrNull => isEmpty ? null : first;
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: AppShadow.dim),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              onBack();
            },
          ),
          Expanded(
            child: Text(
              'checkout'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppSurface.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverToSection extends StatelessWidget {
  const _DeliverToSection({
    required this.addresses,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AddressModel> addresses;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<AddressModel> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, size: 18, color: AppSurface.text),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deliver to',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppSurface.text,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'add_address'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(addresses.length, (i) {
          final a = addresses[i];
          return FadeInUp(
            duration: Duration(milliseconds: 260 + i * 40),
            child: CheckoutAddressCard(
              heroTag: 'checkout-addr-$i-${a.id}',
              address: a,
              selected: i == selectedIndex,
              onSelect: () => onSelect(i),
              onEdit: () => onEdit(a),
            ),
          );
        }),
      ],
    );
  }
}

class _DeliveryEtaCard extends ConsumerWidget {
  const _DeliveryEtaCard({required this.slot});

  final DeliverySlot? slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryEta = ref.appContent.deliveryTimeText;
    return _MiniCard(
      icon: Icons.schedule_rounded,
      iconColor: AppSurface.success,
      title: 'delivery_eta_title'.tr(),
      subtitle: slot != null ? '$deliveryEta · ${slot!.label}' : deliveryEta,
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: AppSurface.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.35,
              color: AppSurface.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
