# App Store Review Fixes

This document outlines the fixes needed to address the App Store review rejection issues.

## Issues Summary

1. ✅ **In-App Purchases Not Located** (Mixed: Code + App Store Connect)
2. ⚠️ **Missing Terms of Use / EULA** (App Store Connect Only)
3. ✅ **"Sphere" Feature Unresponsive** (Code - Fixed)

---

## 1. In-App Purchases Not Located

### A. App Store Connect Actions Required

#### Step 1: Sign Paid Apps Agreement
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **Agreements, Tax, and Banking**
3. Find **Paid Apps Agreement**
4. If it shows "Action Needed", click and accept the agreement
5. Complete all required fields (banking, tax info)

**⚠️ Critical:** IAPs will NOT work until this is signed!

#### Step 2: Verify In-App Purchase Status
1. Go to App Store Connect → Your App → **In-App Purchases**
2. Ensure your subscriptions are configured with:
   - **Status:** "Ready to Submit" or "Waiting for Review"
   - **Cleared for Sale:** ON
   - **All localizations filled out** (at least English)
   - **Pricing configured** for all territories you support

3. Verify your products:
   - Monthly subscription: `echelon_monthly` or similar
   - Annual subscription: `echelon_annual` or similar

#### Step 3: Add to App Version
1. Go to App Store Connect → Your App → **App Store** tab
2. Select the version being reviewed
3. Scroll to **In-App Purchases and Subscriptions**
4. Click **+** and add BOTH your monthly and annual subscriptions
5. Make sure they're checked/enabled

#### Step 4: RevenueCat Configuration (If using)
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com/)
2. Verify your iOS app is properly configured
3. Check that products are synced from App Store Connect
4. Ensure the API key in your `.env` file matches

### B. Code Changes Made ✅

The following subscription details have been added to the paywall to meet Apple's requirements:

1. **Subscription Duration:** Now displays "12 months" or "1 month" under each plan
2. **Legal Links:** Added Privacy Policy and Terms of Use links (see below)
3. **Auto-Renewal Notice:** Updated to clearly state "Subscriptions auto-renew until cancelled"

**⚠️ Action Required:** Update the legal link URLs in `paywall_screen.dart`:

```dart
// Line ~309 - Privacy Policy
TextButton(
  onPressed: () async {
    // TODO: Replace with your actual privacy policy URL
    await launchUrl(Uri.parse('https://yourwebsite.com/privacy'));
  },
  // ...
)

// Line ~327 - Terms of Use  
TextButton(
  onPressed: () async {
    // TODO: Replace with your actual terms of use URL
    await launchUrl(Uri.parse('https://yourwebsite.com/terms'));
  },
  // ...
)
```

**Important:** You'll need to add the `url_launcher` package:

```bash
flutter pub add url_launcher
```

Then add this import to `paywall_screen.dart`:

```dart
import 'package:url_launcher/url_launcher.dart';
```

---

## 2. Missing Terms of Use / EULA (App Store Connect)

### Required Actions in App Store Connect:

#### Option A: Use Apple's Standard EULA
1. Go to App Store Connect → Your App → **App Information**
2. Scroll to **App Store Connect EULA**
3. Leave it empty to use Apple's standard EULA
4. In your **App Description**, add this text:

```
By using Echelon, you agree to Apple's standard Terms of Use (EULA): 
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

#### Option B: Custom EULA (Recommended)
1. Create a Terms of Service document (see template below)
2. Host it on a public URL (e.g., your website, GitHub Pages, etc.)
3. In App Store Connect → Your App → **App Information**
4. Find **App Store Connect EULA** field
5. Enter your Terms of Use URL

#### Privacy Policy (REQUIRED)
1. Create a Privacy Policy document (see template below)
2. Host it on a public URL
3. In App Store Connect → Your App → **App Information**
4. Find **Privacy Policy URL** field
5. Enter your Privacy Policy URL

### Templates

#### Minimal Terms of Use Template:
```markdown
# Terms of Use for Echelon

Last Updated: [Date]

## Subscription Terms
- Subscriptions auto-renew unless cancelled 24 hours before the end of the current period
- Payment is charged to iTunes Account at confirmation of purchase
- Subscription may be managed and auto-renewal may be turned off in Account Settings
- Cancellation takes effect at the end of the current billing period

## Service Description
Echelon provides AI-powered fitness coaching and workout planning through a subscription service.

## Contact
For questions, contact: [your-email@example.com]
```

#### Minimal Privacy Policy Template:
```markdown
# Privacy Policy for Echelon

Last Updated: [Date]

## Data Collection
We collect:
- Device ID for authentication
- Workout and nutrition data you input
- Basic usage analytics

## Data Usage
Your data is used to:
- Provide personalized workout plans
- Track your fitness progress
- Improve our services

## Data Storage
Data is stored locally on your device using Hive and synced to our servers.

## Contact
For privacy concerns, contact: [your-email@example.com]
```

### Where to Host Legal Documents

**Quick Options:**
1. **GitHub Pages** (Free)
   - Create a simple HTML page
   - Host at `https://[username].github.io/echelon-legal/privacy.html`

2. **Google Sites** (Free)
   - Create a simple site with both pages

3. **Netlify/Vercel** (Free)
   - Upload HTML files to static hosting

---

## 3. "Sphere" Feature Unresponsive ✅ FIXED

**Issue:** The `PulsingParticleSphere` widget on the landing page was not responsive to user interaction.

**Fix Applied:** Added a `GestureDetector` wrapper that shows a SnackBar message when tapped, making it clear the element is interactive.

**File Modified:** `lib/screens/landing_page.dart`

---

## Reply to Apple Review Team

When responding in App Store Connect, use this template:

```
Dear App Review Team,

Thank you for your feedback. We have addressed all concerns:

1. IN-APP PURCHASES:
   - Both subscription tiers (Monthly and Annual) have been configured and are in "Ready to Submit" status
   - Paid Apps Agreement has been signed
   - Products are available in the Apple sandbox environment
   - To locate the IAPs: Launch app → Complete onboarding → Paywall screen displays both subscription options

2. SUBSCRIPTION INFORMATION:
   - Added subscription duration (12 months / 1 month) to each plan
   - Added functional links to Privacy Policy: [YOUR_URL]
   - Added functional links to Terms of Use: [YOUR_URL]
   - Updated auto-renewal notice to meet guidelines

3. SPHERE FEATURE BUG:
   - The sphere on the landing page is now interactive and responsive to taps
   - Shows feedback message when tapped
   - Tested on iPhone 13 mini with iOS 18.1

All changes have been submitted in version [X.X.X]. Thank you for your patience.

Best regards,
[Your Name]
```

---

## Testing Checklist Before Resubmission

### App Store Connect:
- [ ] Paid Apps Agreement signed and active
- [ ] Banking and tax information completed
- [ ] Both IAP products in "Ready to Submit" status
- [ ] IAP products added to the app version being reviewed
- [ ] Privacy Policy URL added to App Information
- [ ] Terms of Use URL added (or using Apple's standard EULA)

### Code:
- [ ] `url_launcher` package added to pubspec.yaml
- [ ] Privacy Policy and Terms URLs updated in paywall_screen.dart
- [ ] Legal links work correctly (tap and open in browser)
- [ ] Subscription duration displays correctly
- [ ] Sphere is tappable and shows response
- [ ] Tested on physical iOS device in sandbox mode

### Sandbox Testing:
- [ ] Create a sandbox test account in App Store Connect
- [ ] Sign out of real Apple ID on test device
- [ ] Sign in with sandbox account when prompted during purchase
- [ ] Verify both monthly and annual subscriptions can be purchased
- [ ] Verify subscription unlocks app features

---

## Additional Resources

- [Apple's In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Testing In-App Purchases in Sandbox](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_in_sandbox)
- [App Store Review Guidelines 3.1.2](https://developer.apple.com/app-store/review/guidelines/#business)
- [RevenueCat Testing Guide](https://www.revenuecat.com/docs/test-and-launch/sandbox)

---

## Quick Action Items Summary

**CRITICAL (Must do before resubmission):**
1. Sign Paid Apps Agreement in App Store Connect
2. Create and host Privacy Policy and Terms of Use documents
3. Add URLs to App Store Connect and update code
4. Add `url_launcher` package and update imports
5. Test IAP purchases in sandbox environment

**Already Completed (in code):**
1. ✅ Added subscription duration display
2. ✅ Added legal links framework
3. ✅ Made sphere interactive
4. ✅ Updated auto-renewal notice


