import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../styles.dart';
import '../services/user_service.dart';
import 'main_navigation_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> with SingleTickerProviderStateMixin {
  List<Package>? _packages;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _priceAnimation;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
    
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _priceAnimation = Tween<double>(
      begin: 450.0,
      end: 9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              )
            : Column(
                children: [
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        children: [
                          Text(
                            'Unlock Your Full Potential',
                            style: AppStyles.mainHeader().copyWith(
                              fontSize: 32,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Animated Price Comparison
                          _buildAnimatedPriceComparison(),
                          
                          const SizedBox(height: 24),
                          
                          // Feature Checklist
                          _buildFeaturesList(),
                          
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _errorMessage!,
                                style: AppStyles.questionSubtext().copyWith(
                                  color: Colors.red.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Sticky Bottom Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.accent.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Package Selection (Side by Side)
                        if (_packages != null && _packages!.isNotEmpty)
                          _buildSideBySidePlans(),
                        
                        const SizedBox(height: 16),
                        
                        // Subscribe Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPurchasing || _selectedPackage == null
                                ? null
                                : () => _purchasePackage(_selectedPackage!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.3),
                            ),
                            child: _isPurchasing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: AppStyles.mainText().copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Restore Button
                        TextButton(
                          onPressed: _isPurchasing ? null : _restorePurchases,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          child: Text(
                            'Restore Purchases',
                            style: AppStyles.questionSubtext().copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        // Terms
                        Text(
                          'Auto-renewable. Cancel anytime.',
                          style: AppStyles.questionSubtext().copyWith(
                            fontSize: 9,
                            color: AppColors.accent.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAnimatedPriceComparison() {
    return AnimatedBuilder(
      animation: _priceAnimation,
      builder: (context, child) {
        final currentPrice = _priceAnimation.value;
        final isAnimating = _animationController.isAnimating;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Label
              Text(
                'Personal Trainer Cost',
                style: AppStyles.questionSubtext().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Animated Price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: currentPrice > 100 
                          ? AppColors.accent.withOpacity(0.6)
                          : AppColors.primaryLight,
                    ),
                  ),
                  Text(
                    currentPrice.toInt().toString(),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: currentPrice > 100 
                          ? AppColors.accent.withOpacity(0.6)
                          : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Per month label
              Text(
                'per month',
                style: AppStyles.questionSubtext().copyWith(
                  fontSize: 13,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Comparison text
              if (!isAnimating)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_down,
                            size: 20,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save 96% with Echelon',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'vs. traditional personal training',
                      style: AppStyles.questionSubtext().copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeature('Personalized AI workout plans'),
        const SizedBox(height: 12),
        _buildFeature('Real-time feedback'),
        const SizedBox(height: 12),
        _buildFeature('Hands-free voice coaching'),
        const SizedBox(height: 12),
        _buildFeature('Progress tracking & analytics'),
        const SizedBox(height: 12),
        _buildFeature('Unlimited sessions'),
      ],
    );
  }

  Widget _buildFeature(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 18,
          color: AppColors.primaryLight,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppStyles.mainText().copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySidePlans() {
    // Find monthly and annual packages
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
    
    return Row(
      children: [
        if (annualPackage != null)
          Expanded(
            child: _buildCompactPlanOption(
              package: annualPackage,
              title: 'Yearly',
              badge: 'Save 25%', // Updated: $9.99/mo × 12 = $119.88, vs $89.99 yearly = 25% savings
            ),
          ),
        if (annualPackage != null && monthlyPackage != null)
          const SizedBox(width: 12),
        if (monthlyPackage != null)
          Expanded(
            child: _buildCompactPlanOption(
              package: monthlyPackage,
              title: 'Monthly',
              badge: null,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactPlanOption({
    required Package package,
    required String title,
    String? badge,
  }) {
    final isSelected = _selectedPackage == package;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.accent.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.12)
              : const Color(0xFF1A1A1A),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                children: [
                  // Consistent spacing regardless of badge
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    title,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Price
                  Text(
                    package.storeProduct.priceString,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge positioned on top border
            if (badge != null)
              Positioned(
                top: -20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(0.8),
                        letterSpacing: 0.5,
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

