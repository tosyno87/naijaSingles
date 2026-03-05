import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';
import '../../../home/bloc/searchuser_bloc.dart';

class MatchedPage extends StatefulWidget {
  const MatchedPage({required this.name, required this.currentUser, super.key});
  final String name;
  final UserModel currentUser;

  @override
  MAtchState createState() => MAtchState();
}

class MAtchState extends State<MatchedPage> {
  AssetImage? image;

  @override
  void initState() {
    image = const AssetImage('asset/connected3.gif');
    super.initState();

    unawaited(
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        context
            .read<SearchUserBloc>()
            .add(LoadUserEvent(currentUser: widget.currentUser));
        Navigator.pop(context);
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              color: Theme.of(context).primaryColor,
              elevation: 0,
              child: Text(
                "It's a match\n With ${widget.name} ".tr().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Center(
              child: Image.asset(
                image!.assetName,
              ),
            ),
          ],
        ),
      );
}
