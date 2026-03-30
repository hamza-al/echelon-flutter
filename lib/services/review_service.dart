import 'package:hive_ce/hive_ce.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static const _boxName = 'review';
  static const _openCountKey = 'open_count';
  static const _hasPromptedAfterOnboardingKey = 'prompted_after_onboarding';

  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> trackAppOpen() async {
    final count = _box.get(_openCountKey, defaultValue: 0) as int;
    _box.put(_openCountKey, count + 1);

    final alreadyPromptedOnboarding =
        _box.get(_hasPromptedAfterOnboardingKey, defaultValue: false) as bool;

    if (alreadyPromptedOnboarding && (count + 1) % 3 == 0) {
      await _requestReview();
    }
  }

  static Future<void> promptAfterOnboarding() async {
    final already =
        _box.get(_hasPromptedAfterOnboardingKey, defaultValue: false) as bool;
    if (already) return;

    await _box.put(_hasPromptedAfterOnboardingKey, true);
    await _requestReview();
  }

  static Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}
