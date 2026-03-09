import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utils/custom_toast.dart';
import '../../../../common/widgets/image_widget.dart';

class Layout extends StatelessWidget {
  const Layout({required this.documentSnapshot, super.key});
  final DocumentSnapshot documentSnapshot;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          child: documentSnapshot.get('image_url') != ''
              ? InkWell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(
                          top: 2,
                          bottom: 2,
                          right: 15,
                        ),
                        height: 150,
                        width: 150,
                        color: AppColors.secondaryColor
                            .withValues(alpha: (.5 * 255).toDouble()),
                        padding: const EdgeInsets.all(5),
                        child: Stack(
                          children: <Widget>[
                            CustomCNImage(
                              fit: BoxFit.fitWidth,
                              height: MediaQuery.of(context).size.height * .65,
                              width: MediaQuery.of(context).size.width * .9,
                              imageUrl: documentSnapshot.get('image_url') ?? '',
                            ),
                            Container(
                              alignment: Alignment.bottomRight,
                              child: documentSnapshot.get('isRead') == false
                                  ? const Icon(
                                      Icons.done,
                                      color: AppColors.secondaryColor,
                                      size: 15,
                                    )
                                  : const Icon(
                                      Icons.done_all,
                                      color: AppColors.primaryGreen,
                                      size: 15,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          documentSnapshot.get('time') != null
                              ? DateFormat.yMMMd('en_US')
                                  .add_jm()
                                  .format(
                                    documentSnapshot.get('time').toDate(),
                                  )
                                  .toString()
                              : '',
                          style: const TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    unawaited(
                      Navigator.pushNamed(
                        context,
                        RouteName.largeImageScreen,
                        arguments: documentSnapshot.get('image_url'),
                      ),
                    );
                  },
                )
              : GestureDetector(
                  onLongPress: () {
                    unawaited(
                      Clipboard.setData(
                        ClipboardData(text: documentSnapshot.get('text')),
                      ),
                    );
                    CustomToast.showToast('Message Copied'.tr().toString());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    width: MediaQuery.of(context).size.width * 0.65,
                    margin: const EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                      left: 80,
                      right: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.secondaryColor
                              .withValues(alpha: (.5 * 255).toDouble())
                          : AppColors.primaryGreen.withValues(
                              alpha: (.1 * 255).toDouble(),
                            ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          documentSnapshot.get('text'),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              documentSnapshot.get('time') != null
                                  ? DateFormat.MMMd('en_US')
                                      .add_jm()
                                      .format(
                                        documentSnapshot.get('time').toDate(),
                                      )
                                      .toString()
                                  : '',
                              style: const TextStyle(
                                color: AppColors.secondaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            if (documentSnapshot.get('isRead') == false)
                              const Icon(
                                Icons.done,
                                color: AppColors.secondaryColor,
                                size: 15,
                              )
                            else
                              const Icon(
                                Icons.done_all,
                                color: AppColors.primaryGreen,
                                size: 15,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
