import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionService {
  static final _apiKey = kIsWeb
      ? ''
      : (defaultTargetPlatform == TargetPlatform.iOS
          ? 'appl_RIhGWUSTrVmkjXMJHOSNYJojaBg'
          : 'goog_zNSKIOWAFyyBccMwxlziXRIRCwI');

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
    if (!kIsWeb) {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_apiKey));

      var firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Use current UID for RevenueCat
        Purchases.logIn(firebaseUser.uid).then((loginResult) {
          _customerInfo = loginResult.customerInfo;
          _updateSubscriptionStatus();
        });
      }

      // Listen for auth state changes to re-login to RevenueCat if the user signs in or out
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          try {
            final loginResult = await Purchases.logIn(user.uid);
            _customerInfo = loginResult.customerInfo;
            _updateSubscriptionStatus();
          } catch (e) {
            debugPrint('RevenueCat login error: $e');
          }
        } else {
          try {
            final isAnon = await Purchases.isAnonymous;
            if (!isAnon) {
              _customerInfo = await Purchases.logOut();
              _updateSubscriptionStatus();
            }
          } catch (e) {
            debugPrint('RevenueCat logout error: $e');
          }
        }
      });

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      Purchases.getCustomerInfo().then((customerInfo) {
        _customerInfo = customerInfo;
        _updateSubscriptionStatus();
      });
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    if (!kIsWeb) {
      _customerInfo = customerInfo;
      _updateSubscriptionStatus();
    }
  }

  void _updateSubscriptionStatus() {
    if (!kIsWeb) {
      final newSubscribedState =
          _customerInfo.entitlements.active.containsKey('cloud-storage');
      if (newSubscribedState != _isSubscribed) {
        _isSubscribed = newSubscribedState;
        _subscriptionStateController.add(_isSubscribed);
      }
    }
  }

  Future<void> purchaseSubscription() async {
    if (!kIsWeb) {
      try {
        // Get the current user from Firebase Auth (should already be signed in)
        var firebaseUser = FirebaseAuth.instance.currentUser;

        if (firebaseUser == null) {
          debugPrint(
              'Error: User must be signed in before purchasing subscription');
          return;
        }

        // Log in to RevenueCat with current UID
        await Purchases.logIn(firebaseUser.uid);

        // Present the paywall
        await RevenueCatUI.presentPaywallIfNeeded("cloud-storage");
      } catch (e) {
        debugPrint('Error purchasing subscription: $e');
      }
    }
  }
}
