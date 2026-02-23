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
          // Pre-select the first package (typically monthly)
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
      
      // Check if user now has an active entitlement
      final customerInfo = purchaseResult.customerInfo;
      if (customerInfo.entitlements.all.isNotEmpty) {
        final hasActiveEntitlement = customerInfo.entitlements.all.values
            .any((entitlement) => entitlement.isActive);
        
        if (hasActiveEntitlement && mounted) {
          // Successfully purchased - navigate to main app
          _onPurchaseSuccess();
        }
      }
    } on PurchasesErrorCode catch (e) {
      setState(() {
        _isPurchasing = false;
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          _errorMessage = null; // Don't show error for cancellations
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
    // Save subscription status to Hive
    await UserService.updateSubscriptionStatus(true);
    
    // Navigate to main navigation screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    }
  }

  // TODO: Replace these URLs with your actual legal document URLs
  static const String _privacyPolicyUrl = 'https://romantic-okapi-579.notion.site/Echelon-Privacy-Policy-Terms-of-Service-2de17c99989380ce8cf4e4729a0ac1a6?pvs=74';
  static const String _termsOfUseUrl = 'https://romantic-okapi-579.notion.site/Echelon-Privacy-Policy-Terms-of-Service-2de17c99989380ce8cf4e4729a0ac1a6?pvs=74';

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(_privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Privacy Policy URL not configured',
              style: AppStyles.mainText().copyWith(fontSize: 14),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _openTermsOfUse(BuildContext context) async {
    final uri = Uri.parse(_termsOfUseUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terms of Use URL not configured',
              style: AppStyles.mainText().copyWith(fontSize: 14),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              )
            : Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      // Top section with title, sphere, and features
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Title
                              Text(
                                'Your plan\nis built.',
                                style: AppStyles.mainHeader().copyWith(
                                  fontSize: 36,
                                  color: AppColors.accent,
                                  height: 1.1,
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // Subtitle
                              Text(
                                'Unlock Echelon to get started.',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 16,
                                  color: AppColors.accent.withOpacity(0.6),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Feature list
                              _buildFeaturesList(),

                              const SizedBox(height: 20),

                              // Social proof
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...List.generate(5, (_) => Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: const Color(0xFFFBBF24),
                                      ),
                                    )),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Join thousands training smarter',
                                      style: AppStyles.mainText().copyWith(
                                        fontSize: 13,
                                        color: AppColors.accent.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom pricing card
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.accent.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Package Selection
                          if (_packages != null && _packages!.isNotEmpty)
                            _buildPricingOptions(),
                          
                          const SizedBox(height: 12),
                          
                          // Claim offer button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPurchasing || _selectedPackage == null
                                  ? null
                                  : () => _purchasePackage(_selectedPackage!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.3),
                              ),
                              child: _isPurchasing
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.background,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Unlock Echelon',
                                      style: AppStyles.mainText().copyWith(
                                        color: AppColors.background,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Footer text
                          Text(
                            'Cancel anytime in Settings',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 12,
                              color: AppColors.accent.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Restore and legal links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _isPurchasing ? null : _restorePurchases,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Restore',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 11,
                                    color: AppColors.accent.withOpacity(0.6),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(
                                ' • ',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 11,
                                  color: AppColors.accent.withOpacity(0.6),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openPrivacyPolicy(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Privacy',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 11,
                                    color: AppColors.accent.withOpacity(0.6),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(
                                ' • ',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 11,
                                  color: AppColors.accent.withOpacity(0.6),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openTermsOfUse(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Terms',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 11,
                                    color: AppColors.accent.withOpacity(0.6),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _errorMessage!,
                                style: AppStyles.mainText().copyWith(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    const features = [
      (Icons.mic_none_rounded, 'Hands-free voice logging', 'Log sets by speaking — no tapping needed'),
      (Icons.auto_awesome, 'AI coach that adapts to you', 'Personalized advice based on your progress'),
      (Icons.restaurant_menu_rounded, 'Smart nutrition tracking', 'Calorie and macro targets tailored to your goal'),
      (Icons.calendar_month_rounded, 'Workout splits and scheduling', 'Structured plans that fit your routine'),
      (Icons.insights_rounded, 'Progress analytics and graphs', 'See your strength gains over time'),
    ];
    
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature.$1,
                  size: 20,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.$2,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.$3,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        color: AppColors.accent.withOpacity(0.5),
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

    // Compute dynamic pricing strings
    String annualMonthly = '';
    String discountBadge = '';
    String monthlyOriginal = '';

    if (annualPackage != null) {
      final annualPrice = annualPackage.storeProduct.price;
      final monthlyEquiv = annualPrice / 12;
      annualMonthly = '\$${monthlyEquiv.toStringAsFixed(0)}/mo';

      if (monthlyPackage != null) {
        final monthlyPrice = monthlyPackage.storeProduct.price;
        final fullYearAtMonthly = monthlyPrice * 12;
        if (fullYearAtMonthly > annualPrice) {
          final savings = ((1 - annualPrice / fullYearAtMonthly) * 100).round();
          discountBadge = 'MOST POPULAR $savings% OFF';
          monthlyOriginal = '\$${fullYearAtMonthly.toStringAsFixed(0)}';
        }
      }
    }

    return Column(
      children: [
        if (annualPackage != null)
          _buildPricingCard(
            package: annualPackage,
            title: 'Yearly',
            subtitle: annualMonthly,
            billedText: 'Billed yearly at',
            originalPrice: monthlyOriginal,
            discountBadge: discountBadge,
            isPopular: true,
          ),
        if (annualPackage != null && monthlyPackage != null)
          const SizedBox(height: 10),
        if (monthlyPackage != null)
          _buildPricingCard(
            package: monthlyPackage,
            title: 'Monthly',
            subtitle: '${monthlyPackage.storeProduct.priceString}/mo',
            billedText: 'Billed monthly at',
            originalPrice: '',
            discountBadge: '',
            isPopular: false,
          ),
      ],
    );
  }

  Widget _buildPricingCard({
    required Package package,
    required String title,
    required String subtitle,
    required String billedText,
    required String originalPrice,
    required String discountBadge,
    required bool isPopular,
  }) {
    final isSelected = _selectedPackage == package;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.accent.withOpacity(0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Left side - title and subtitle
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppStyles.mainText().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - billing info
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (billedText.isNotEmpty)
                        Text(
                          billedText,
                          style: AppStyles.mainText().copyWith(
                            fontSize: 11,
                            color: AppColors.accent.withOpacity(0.6),
                          ),
                        ),
                      if (billedText.isNotEmpty)
                        const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (originalPrice.isNotEmpty) ...[
                            Text(
                              originalPrice,
                              style: AppStyles.mainText().copyWith(
                                fontSize: 12,
                                color: AppColors.accent.withOpacity(0.5),
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.accent.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            package.storeProduct.priceString,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Discount badge
            if (isPopular && discountBadge.isNotEmpty)
              Positioned(
                top: -20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      discountBadge,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


