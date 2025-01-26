import 'dart:developer';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:remoteo/app/utils/app_strings.dart';
import 'package:remoteo/app/utils/app_utils.dart';

import '../app/router.dart';

class InAppSubscription {

  static Offerings? _offerings;
  static bool isSubscribed = false;

  ///Init subscription
  static Future<void> initSubscription() async {
    // await Purchases.setDebugLogsEnabled(true);
    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(AppStrings.revenueCatGoogleKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(AppStrings.revenueCatAppleKey);
    }
    await Purchases.configure(configuration!);
  }

  /// Fetch offerings
  static Future<Offerings?> fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      return _offerings;
    } catch (e) {
      print("Error fetching offerings: $e");
      return null;
    }
  }

  ///Purchase subscription
  static Future<bool> purchaseSubscription(Package package) async {
    try {
      CustomerInfo customerInfo =
      await Purchases.purchasePackage(
          package);
      EntitlementInfo? entitlement =
      customerInfo.entitlements.all[AppStrings.revenueCatEntitlement];
      if (entitlement != null && entitlement.isActive) {
        isSubscribed = true;
        log("Subscription successful!");
        return true;
      } else {
        AppUtils.showCustomSnackbar(Get.context!, "Something went wrong!");
        log("Subscription not active after purchase.");
        return false;
      }
    } catch (e) {
      // AppUtils.showCustomSnackbar(Get.context!, "Error:$e");
      log("Purchase failed=>${e}");
      return false;
    }
  }

  /// Check active subscription
  static Future<void> checkActiveSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all[AppStrings.revenueCatEntitlement] != null &&
          customerInfo.entitlements.all[AppStrings.revenueCatEntitlement]?.isActive == true) {
       AppUtils.showCustomSnackbar(Get.context!,"ACTIVE");
        isSubscribed = true;
      }else{
        AppUtils.showCustomSnackbar(Get.context!,"INACTIVE");
        isSubscribed = false;
      }
    } catch (e) {
      AppUtils.showCustomSnackbar(Get.context!,"Error checking subscription: $e");
      log("Error checking subscription: $e");
      isSubscribed = false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      final purchaserInfo = await Purchases.restorePurchases();
      if (purchaserInfo.entitlements.active.isNotEmpty) {
        isSubscribed = true;
        log("Restore successful!");
        AppUtils.showCustomSnackbar(Get.context!,"Subscription Restored successfully!");
        Get.toNamed(RouteName.wifiConnection);
        return true;
      }else{
        AppUtils.showCustomSnackbar(Get.context!,"You don't have any subscription.");
      }
    } catch (e) {
      log("Restore error: $e");
      AppUtils.showCustomSnackbar(Get.context!,"Something went wrong!");
    }
    return false;
  }

  /// Close purchases
  static Future<bool> closePurchases() async {
    try {
      await Purchases.close();
    } catch (e) {
      log("Purchase close error: $e");
    }
    return false;
  }

}