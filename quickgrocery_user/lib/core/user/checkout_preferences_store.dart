import 'dart:convert';

import 'package:quickgrocery/view/cart/domain/cart_models.dart';

import 'user_profile_cache.dart';
import 'user_profile_repository.dart';

/// Restores / persists checkout selections across sessions.
abstract final class CheckoutPreferencesStore {
  static Future<CheckoutState?> loadInitial() async {
    final pmId = await UserProfileCache.readLastPaymentMethodId();
    final idx = await UserProfileCache.readLastAddressIndex();
    final instrMap = await UserProfileCache.lastDeliveryInstructionsMap();

    PaymentMethod? pm;
    if (pmId != null) {
      pm = PaymentMethod.fromId(pmId);
    }

    DeliveryInstructions? instructions;
    if (instrMap != null) {
      instructions = DeliveryInstructions(
        instructionText: instrMap['instructionText']?.toString() ?? '',
        leaveAtDoor: instrMap['leaveAtDoor'] == true,
        gateCode: instrMap['gateCode']?.toString() ?? '',
        landmark: instrMap['landmark']?.toString() ?? '',
        notes: instrMap['notes']?.toString() ?? '',
      );
    }

    if (pm == null && idx == null && instructions == null) return null;

    return CheckoutState.initial.copyWith(
      paymentMethod: pm,
      selectedAddressIndex: idx ?? 0,
      instructions: instructions ?? CheckoutState.initial.instructions,
    );
  }

  static Future<void> persistFromState(CheckoutState state) async {
    final uid = UserProfileRepository.currentUid;
    final instrJson = jsonEncode({
      'instructionText': state.instructions.instructionText,
      'leaveAtDoor': state.instructions.leaveAtDoor,
      'gateCode': state.instructions.gateCode,
      'landmark': state.instructions.landmark,
      'notes': state.instructions.notes,
    });

    await UserProfileCache.saveCheckoutPrefs(
      paymentMethodId: state.paymentMethod.id,
      addressIndex: state.selectedAddressIndex,
      instructionsJson: instrJson,
    );

    if (uid != null) {
      await UserProfileRepository().saveCheckoutPreferences(
        uid: uid,
        paymentMethodId: state.paymentMethod.id,
        addressIndex: state.selectedAddressIndex,
        deliveryInstructions: {
          'instructionText': state.instructions.instructionText,
          'leaveAtDoor': state.instructions.leaveAtDoor,
          'gateCode': state.instructions.gateCode,
          'landmark': state.instructions.landmark,
          'notes': state.instructions.notes,
        },
      );
    }
  }

  static Future<void> recordSuccessfulOrder({
    required String orderId,
    required CheckoutState state,
  }) async {
    await persistFromState(state);
    final uid = UserProfileRepository.currentUid;
    if (uid == null) return;
    await UserProfileRepository().saveCheckoutPreferences(
      uid: uid,
      paymentMethodId: state.paymentMethod.id,
      addressIndex: state.selectedAddressIndex,
      lastOrderId: orderId,
      deliveryInstructions: {
        'instructionText': state.instructions.instructionText,
        'leaveAtDoor': state.instructions.leaveAtDoor,
        'gateCode': state.instructions.gateCode,
        'landmark': state.instructions.landmark,
        'notes': state.instructions.notes,
      },
    );
  }
}
