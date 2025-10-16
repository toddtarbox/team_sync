import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionService {
  static final _apiKey = Platform.isIOS
      ? 'appl_RIhGWUSTrVmkjXMJHOSNYJojaBg'
      : 'goog_zNSKIOWAFyyBccMwxlziXRIRCwI';

  static final SubscriptionService instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return instance;
  }

  SubscriptionService._internal();

  final _subscriptionStateController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionState => _subscriptionStateController.stream;

  late CustomerInfo _customerInfo;
  CustomerInfo get customerInfo => _customerInfo;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(_apiKey));
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _customerInfo = await Purchases.getCustomerInfo();
    _updateSubscriptionStatus();
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    _updateSubscriptionStatus();
  }

  void _updateSubscriptionStatus() {
    final newSubscribedState =
        _customerInfo.entitlements.active.containsKey('cloud-storage');
    if (newSubscribedState != _isSubscribed) {
      _isSubscribed = newSubscribedState;
      _subscriptionStateController.add(_isSubscribed);
    }
  }

  Future<void> purchaseSubscription() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final package = offerings.current!.availablePackages.first;
        await RevenueCatUI.presentPaywallIfNeeded(package.identifier);
      }
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
    }
  }
}
