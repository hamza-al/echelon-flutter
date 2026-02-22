# App Store Resubmission Checklist

## ✅ Code Changes Completed

- [x] Added subscription duration display to paywall plans
- [x] Added Privacy Policy and Terms of Use links to paywall
- [x] Made sphere on landing page interactive (shows feedback on tap)
- [x] Added `url_launcher` package to pubspec.yaml
- [x] Implemented URL opening functionality with error handling

## 🔄 Configuration Required (Before Resubmission)

### 1. Install Dependencies
```bash
cd /Users/hamzaalsorkhy/Desktop/personal/echelon/echelon
flutter pub get
```

### 2. Update Legal Document URLs
Edit `lib/screens/paywall_screen.dart` and replace these constants (around line 178-179):

```dart
static const String _privacyPolicyUrl = 'https://romantic-okapi-579.notion.site/Echelon-Privacy-Policy-Terms-of-Service-2de17c99989380ce8cf4e4729a0ac1a6?pvs=74';
static const String _termsOfUseUrl = 'https://yourwebsite.com/terms';
```

**Replace with your actual URLs!**

### 3. Create Legal Documents
You need to create and host:
- [ ] Privacy Policy
- [ ] Terms of Use (EULA)

**Quick Hosting Options:**
- GitHub Pages (free)
- Google Sites (free)
- Netlify/Vercel (free)
- Your own website

See `APP_STORE_REVIEW_FIXES.md` for templates.

### 4. App Store Connect Setup

#### A. Paid Apps Agreement
- [ ] Go to App Store Connect → Agreements, Tax, and Banking
- [ ] Sign Paid Apps Agreement (if not already signed)
- [ ] Complete banking information
- [ ] Complete tax forms

#### B. In-App Purchases
- [ ] Verify both subscriptions (monthly & annual) are "Ready to Submit"
- [ ] Verify "Cleared for Sale" is ON for both
- [ ] Add subscriptions to your app version:
  - Go to App Store Connect → Your App → [Version]
  - Scroll to "In-App Purchases and Subscriptions"
  - Click + and add both products

#### C. Legal Information
- [ ] Go to App Store Connect → Your App → App Information
- [ ] Add Privacy Policy URL
- [ ] Add Terms of Use URL or leave blank for Apple's standard EULA

#### D. App Description (Optional but Helpful)
Add to your app description:
```
Terms of Use: [YOUR_TERMS_URL]
Privacy Policy: [YOUR_PRIVACY_URL]
```

### 5. Testing Before Submission

#### Sandbox Testing
- [ ] Create a sandbox test account in App Store Connect
- [ ] Test monthly subscription purchase
- [ ] Test annual subscription purchase
- [ ] Verify app unlocks after purchase
- [ ] Test "Restore Purchases" functionality

#### UI Testing
- [ ] Tap the sphere on landing page (should show snackbar message)
- [ ] Tap Privacy Policy link on paywall (should open browser)
- [ ] Tap Terms of Use link on paywall (should open browser)
- [ ] Verify subscription durations display correctly

### 6. Build and Submit
```bash
# Clean build
flutter clean
flutter pub get

# iOS build
flutter build ios --release

# Then open Xcode and archive/submit
```

## 📝 Reply to Apple Review Team

Use this template when responding in App Store Connect:

```
Dear App Review Team,

Thank you for your feedback. We have addressed all issues:

1. IN-APP PURCHASES:
   - Both subscription tiers have been configured and added to this version
   - Paid Apps Agreement is signed and active
   - Products are available in sandbox environment
   - To access: Launch app → Complete onboarding → Paywall displays both subscription options

2. SUBSCRIPTION INFORMATION ADDED:
   - Subscription duration now displayed (12 months / 1 month)
   - Privacy Policy link: [YOUR_URL]
   - Terms of Use link: [YOUR_URL]
   - Auto-renewal terms updated to meet guidelines

3. SPHERE FEATURE:
   - Now fully responsive to user interaction
   - Provides feedback when tapped
   - Tested on iPhone 13 mini with iOS 18.1

All changes submitted in version [X.X.X].

Best regards,
[Your Name]
```

## ⚠️ Critical Items (Must Complete)

Before resubmitting, you **MUST**:

1. ✅ Run `flutter pub get` to install url_launcher
2. ⚠️ Create and host Privacy Policy
3. ⚠️ Create and host Terms of Use
4. ⚠️ Update URLs in paywall_screen.dart
5. ⚠️ Sign Paid Apps Agreement in App Store Connect
6. ⚠️ Add IAP products to your app version
7. ⚠️ Test IAP purchases in sandbox
8. ⚠️ Add legal URLs to App Store Connect

## 🔍 Quick Test Commands

```bash
# Check if url_launcher is installed
flutter pub deps | grep url_launcher

# Run app in debug mode
flutter run

# Build for release
flutter build ios --release
```

## 📚 Documentation

- See `APP_STORE_REVIEW_FIXES.md` for detailed explanations
- Privacy Policy and Terms of Use templates included

## ✨ What Changed in Code

### Files Modified:
1. `lib/screens/paywall_screen.dart`
   - Added subscription duration display
   - Added Privacy Policy and Terms of Use links
   - Implemented URL opening functionality
   - Updated auto-renewal notice

2. `lib/screens/landing_page.dart`
   - Made sphere interactive with GestureDetector
   - Added feedback on tap

3. `pubspec.yaml`
   - Added url_launcher: ^6.3.1

### Files Created:
1. `APP_STORE_REVIEW_FIXES.md` - Detailed fix guide
2. `SUBMISSION_CHECKLIST.md` - This checklist

---

Last Updated: [Current Date]

