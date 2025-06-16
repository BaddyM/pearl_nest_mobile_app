// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryblue : AppTheme.whiteColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primaryblue : AppTheme.greyColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryblue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.whiteColor : AppTheme.greyColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
