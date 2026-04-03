import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk_platform_interface.dart';

class TikTokTrackingService {
  TikTokTrackingService._();
  static final TikTokTrackingService _instance = TikTokTrackingService._();
  static TikTokTrackingService get instance => _instance;

  final _sdk = TiktokBusinessSdk();

  bool get _supported => Platform.isIOS || Platform.isAndroid;

  void trackStartOnboarding() {
    debugPrint('[TikTok] Registration → start_onboarding');
    if (!_supported) return;
    _sdk.trackTTEvent(
      event: EventName.Registration,
      eventId: 'start_onboarding',
    );
  }

  void trackSubscribe() {
    debugPrint('[TikTok] Subscribe → subscription_purchase');
    if (!_supported) return;
    _sdk.trackTTEvent(
      event: EventName.Subscribe,
      eventId: 'subscription_purchase',
    );
  }
}
