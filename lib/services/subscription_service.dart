import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
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

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(_apiKey));

    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      Purchases.logIn(firebaseUser.uid).then((loginResult) {
        _customerInfo = loginResult.customerInfo;
        _updateSubscriptionStatus();
      });
    }

    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    Purchases.getCustomerInfo().then((customerInfo) {
      _customerInfo = customerInfo;
      _updateSubscriptionStatus();
    });
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
      AuthProvider provider;
      if (Platform.isIOS) {
        provider = AppleAuthProvider()
            .addScope('ASAuthorizationScopeFullName')
            .addScope('ASAuthorizationScopeEmail');
      } else {
        provider = GoogleAuthProvider();
      }

      // Get the current user from Firebase Auth.
      var firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        final userCredential =
            await FirebaseAuth.instance.signInWithProvider(provider);
        firebaseUser = userCredential.user;
      }

      // Log in to RevenueCat with the Firebase user's UID.
      // This links the RevenueCat customer to your Firebase user.
      await Purchases.logIn(firebaseUser!.uid);

      // Present the paywall. `presentPaywallIfNeeded` is a convenient method
      // that checks if the user already has the required entitlement.
      await RevenueCatUI.presentPaywallIfNeeded("cloud-storage");
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
    }
  }
}
