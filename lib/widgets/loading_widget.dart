import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.height});
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.8,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: AppTheme.accentGreen,
      ),
    );
    ;
  }
}
