import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../../common/constants/app_colors.dart';

class FaceBookButton extends StatelessWidget {
  const FaceBookButton({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Material(
        elevation: 2,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: !isDarkMode
                    ? LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.primaryGreen.withValues(
                            alpha: (.5 * 255).toDouble(),
                          ),
                          AppColors.primaryGreen.withValues(
                            alpha: (.8 * 255).toDouble(),
                          ),
                          AppColors.primaryGreen,
                          AppColors.primaryGreen,
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreenDark,
                        ],
                      ),
              ),
              height: MediaQuery.of(context).size.height * .065,
              width: MediaQuery.of(context).size.width * .8,
              child: Center(
                child: Text(
                  'LOG IN WITH FACEBOOK'.tr().toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
