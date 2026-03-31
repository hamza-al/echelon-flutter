import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles.dart';
import '../services/user_service.dart';
import 'main_navigation_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<Package>? _packages;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final offerings = await Purchases.getOfferings();

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          _selectedPackage = _packages!.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No subscription plans available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load plans: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    try {
      setState(() {
        _isPurchasing = true;
        _errorMessage = null;
      });

      final purchaseResult = await Purchases.purchasePackage(package);

      final customerInfo = purchaseResult.customerInfo;
      if (customerInfo.entitlements.all.isNotEmpty) {
        final hasActiveEntitlement = customerInfo.entitlements.all.values
            .any((entitlement) => entitlement.isActive);

        if (hasActiveEntitlement && mounted) {
          _onPurchaseSuccess();
        }
      }
    } on PurchasesErrorCode catch (e) {
      setState(() {
        _isPurchasing = false;
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          _errorMessage = null;
        } else {
          _errorMessage = 'Purchase failed: ${e.toString()}';
        }
      });
    } catch (e) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isPurchasing = true;
        _errorMessage = null;
      });

      final purchaserInfo = await Purchases.restorePurchases();

      final hasActiveEntitlement = purchaserInfo.entitlements.all.values
          .any((entitlement) => entitlement.isActive);

      if (hasActiveEntitlement && mounted) {
        _onPurchaseSuccess();
      } else {
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'No active subscriptions found';
        });
      }
    } catch (e) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Failed to restore: ${e.toString()}';
      });
    }
  }

  void _onPurchaseSuccess() async {
    await UserService.updateSubscriptionStatus(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    }
  }

  static const String _privacyPolicyUrl =
      'https://romantic-okapi-579.notion.site/Echelon-Privacy-Policy-Terms-of-Service-2de17c99989380ce8cf4e4729a0ac1a6?pvs=74';
  static const String _termsOfUseUrl =
      'https://romantic-okapi-579.notion.site/Echelon-Privacy-Policy-Terms-of-Service-2de17c99989380ce8cf4e4729a0ac1a6?pvs=74';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ?  Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlock Echelon',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5,
                              color: AppColors.overlay.withValues(alpha: 0.9),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your plan, your coach, and your nutrition — all in one place.',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              color: AppColors.overlay.withValues(alpha: 0.3),
                              height: 1.45,
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildFeatures(),

                          const SizedBox(height: 24),

                          // Testimonial
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.overlay.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.overlay.withValues(alpha: 0.06),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (_) => Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: const Color(0xFFFBBF24)
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '"Replaced 3 apps for me. Voice logging is a game changer."',
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color:
                                          AppColors.overlay.withValues(alpha: 0.3),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- Pricing ---
                          if (_packages != null && _packages!.isNotEmpty)
                            _buildPricingOptions(),

                          const SizedBox(height: 16),

                          // CTA button
                          GestureDetector(
                            onTap: _isPurchasing || _selectedPackage == null
                                ? null
                                : () =>
                                    _purchasePackage(_selectedPackage!),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _isPurchasing
                                    ? AppColors.overlay.withValues(alpha: 0.04)
                                    : AppColors.overlay.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppColors.overlay.withValues(alpha: 0.08),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: _isPurchasing
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Start Training Smarter',
                                        style:
                                            AppStyles.mainText().copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: Text(
                              'Cancel anytime in Settings',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 12,
                                color:
                                    AppColors.overlay.withValues(alpha: 0.2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Restore & legal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legalLink('Restore',
                                  _isPurchasing ? null : _restorePurchases),
                              _dot(),
                              _legalLink('Privacy',
                                  () => _openUrl(_privacyPolicyUrl)),
                              _dot(),
                              _legalLink(
                                  'Terms', () => _openUrl(_termsOfUseUrl)),
                            ],
                          ),

                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Text(
                                  _errorMessage!,
                                  style: AppStyles.mainText().copyWith(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                          SizedBox(height: bottomPad + 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeatures() {
    const features = [
      (Icons.mic_none_rounded, 'Voice logging',
          'Say what you did — no typing needed'),
      (Icons.auto_awesome, 'AI coaching',
          'Adapts to your progress in real time'),
      (Icons.restaurant_menu_rounded, 'Smart nutrition',
          'Calories & macros matched to your goal'),
      (Icons.calendar_month_rounded, 'Structured training',
          'Your split planned out every day'),
      (Icons.insights_rounded, 'Progress tracking',
          'PRs, volume trends, and analytics'),
      (Icons.bedtime_rounded, 'Sleep tracking',
          'Log, chart, and improve your recovery'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.overlay.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  f.$1,
                  size: 16,
                  color: AppColors.overlay.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$2,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.overlay.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$3,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        color: AppColors.overlay.withValues(alpha: 0.3),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingOptions() {
    Package? monthlyPackage;
    Package? annualPackage;

    for (final package in _packages!) {
      final id = package.storeProduct.identifier.toLowerCase();
      final type = package.packageType;

      if (id.contains('annual') || type == PackageType.annual) {
        annualPackage = package;
      } else if (id.contains('monthly') || type == PackageType.monthly) {
        monthlyPackage = package;
      }
    }

    String annualMonthly = '';
    String discountBadge = '';

    if (annualPackage != null && monthlyPackage != null) {
      final annualPrice = annualPackage.storeProduct.price;
      final monthlyEquiv = annualPrice / 12;
      annualMonthly = '\$${monthlyEquiv.toStringAsFixed(0)}/mo';

      final monthlyPrice = monthlyPackage.storeProduct.price;
      final fullYearAtMonthly = monthlyPrice * 12;
      if (fullYearAtMonthly > annualPrice) {
        final savings =
            ((1 - annualPrice / fullYearAtMonthly) * 100).round();
        discountBadge = 'Save $savings%';
      }
    }

    return Column(
      children: [
        if (annualPackage != null)
          _buildPricingCard(
            package: annualPackage,
            title: 'Yearly',
            subtitle: annualMonthly,
            price: annualPackage.storeProduct.priceString,
            badge: discountBadge,
            isPopular: true,
          ),
        if (annualPackage != null && monthlyPackage != null)
          const SizedBox(height: 10),
        if (monthlyPackage != null)
          _buildPricingCard(
            package: monthlyPackage,
            title: 'Monthly',
            subtitle: '${monthlyPackage.storeProduct.priceString}/mo',
            price: monthlyPackage.storeProduct.priceString,
            badge: '',
            isPopular: false,
          ),
      ],
    );
  }

  Widget _buildPricingCard({
    required Package package,
    required String title,
    required String subtitle,
    required String price,
    required String badge,
    required bool isPopular,
  }) {
    final isSelected = _selectedPackage == package;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = package),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.overlay.withValues(alpha: 0.06)
              : AppColors.overlay.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.4)
                : AppColors.overlay.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.6)
                      : AppColors.overlay.withValues(alpha: 0.15),
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppStyles.mainText().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.overlay.withValues(alpha: 0.8),
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      color: AppColors.overlay.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.overlay.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalLink(String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          text,
          style: AppStyles.mainText().copyWith(
            fontSize: 11,
            color: AppColors.overlay.withValues(alpha: 0.2),
            decoration: TextDecoration.underline,
            decorationColor: AppColors.overlay.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Text(
      '·',
      style: AppStyles.mainText().copyWith(
        fontSize: 11,
        color: AppColors.overlay.withValues(alpha: 0.15),
      ),
    );
  }
}
