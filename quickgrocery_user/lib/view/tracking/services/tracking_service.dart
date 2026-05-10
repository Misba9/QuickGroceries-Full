import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickgrocery/models/delivery_boy_model.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingService extends ChangeNotifier {
  DeliveryBoyModel? deliveryBoyModel;

  Future<void> getDeliveryBoyById(String id) async {
    if (id != '') {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        deliveryBoyModel = DeliveryBoyModel.fromFirestore(
          docSnapshot.data()!,
          docSnapshot.id,
        );
        notifyListeners();
      }
    }
  }

  String timeFormate(String date) {
    DateTime now = DateTime.parse(date);

    return DateFormat('hh:mm a').format(now);
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }
}
