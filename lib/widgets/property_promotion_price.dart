import 'package:flutter/material.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class PropertyPromotionPrice extends StatelessWidget {
  const PropertyPromotionPrice({
    super.key,
    required this.property,
    this.fontSize = 18,
    this.showPeriod = true,
  });

  final Property property;
  final double fontSize;
  final bool showPeriod;

  @override
  Widget build(BuildContext context) {
    final formatter = ProfileService();
    final promoted = property.hasActivePromotion;
    final price = promoted ? property.promotionalPrice : property.price.toInt();
    final period = property.priceType.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (promoted)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.currencyConverter(price: property.price.toInt()),
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  color: AppTheme.getSecondaryTextColor(context),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  property.promotionDiscountType == 'PERCENTAGE'
                      ? '${property.promotionDiscountValue}% off'
                      : 'Save ${formatter.currencyConverter(price: property.currentPromotionDiscount)}',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: fontSize * 0.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatter.currencyConverter(price: price),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryblue,
                ),
              ),
              if (showPeriod && period.isNotEmpty && period != 'undefined')
                TextSpan(
                  text: ' $period',
                  style: TextStyle(
                    fontSize: fontSize * 0.65,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
