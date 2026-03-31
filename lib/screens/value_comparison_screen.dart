import 'package:flutter/material.dart';
import '../styles.dart';

class ValueComparisonScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const ValueComparisonScreen({super.key, required this.onContinue});

  @override
  State<ValueComparisonScreen> createState() => _ValueComparisonScreenState();
}

class _ValueComparisonScreenState extends State<ValueComparisonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  static const _rows = [
    ('Custom workout plan', true, true),
    ('Nutrition coaching', true, true),
    ('Progress tracking', true, true),
    ('Voice logging', true, false),
    ('Available 24/7', true, false),
    ('No scheduling hassle', true, false),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skip the trainer.\nKeep the results.',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                        color: AppColors.overlay.withValues(alpha: 0.9),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Everything a personal trainer gives you — programming, nutrition, accountability — for a fraction of the cost.',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 14,
                        color: AppColors.overlay.withValues(alpha: 0.3),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildPriceComparison(),

                    const SizedBox(height: 16),

                    _buildSavingsCard(),

                    const SizedBox(height: 16),

                    _buildComparisonTable(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 24),
              child: GestureDetector(
                onTap: widget.onContinue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.overlay.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.overlay.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'See plans',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.overlay.withValues(alpha: 0.85),
                      ),
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

  Widget _buildPriceComparison() {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Column(
          children: [
            // Personal Trainer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Trainer',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    color: AppColors.overlay.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '\$200–400/month',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.overlay.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: _anim.value,
                  backgroundColor: AppColors.overlay.withValues(alpha: 0.04),
                  color: AppColors.overlay.withValues(alpha: 0.15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Echelon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Echelon',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    color: AppColors.overlay.withValues(alpha: 0.7),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$6',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '/month',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 12,
                        color: AppColors.overlay.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 6,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: _anim.value * 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Save \$2,300+',
            style: AppStyles.mainText().copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.overlay.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'per year compared to a personal trainer',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              color: AppColors.overlay.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 64,
                child: Center(
                  child: Text(
                    'Trainer',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.overlay.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Center(
                  child: Text(
                    'Echelon',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._rows.map((row) => _comparisonRow(row.$1, row.$2, row.$3)),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, bool echelon, bool trainer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                color: AppColors.overlay.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Center(
              child: Icon(
                trainer ? Icons.check_rounded : Icons.close_rounded,
                size: 18,
                color: trainer
                    ? AppColors.overlay.withValues(alpha: 0.3)
                    : AppColors.overlay.withValues(alpha: 0.12),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Center(
              child: Icon(
                echelon ? Icons.check_rounded : Icons.close_rounded,
                size: 18,
                color: echelon
                    ? AppColors.primaryLight.withValues(alpha: 0.7)
                    : AppColors.overlay.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
