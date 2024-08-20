import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';
import '../../../../models/user_model.dart';
import '../../../street_view/street_view.dart';

// street view icon that placed on user cards

class StreetViewIcon extends StatelessWidget {
  final UserModel currentUser;
  final UserModel user;
  const StreetViewIcon(
      {super.key, required this.currentUser, required this.user});

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 10,
        right: 15,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Scaffold(
                          backgroundColor: Theme.of(context).primaryColor,
                          appBar: AppBar(
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            elevation: 0,
                          ),

                          // street view html page
                          body: StreetViewPanoramaInit(
                            currentUser: currentUser,
                            user: [user],
                            currentAddressName: "",
                            fromSingleuser: true,
                          ),
                        )));
          },
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                "asset/street-view.png",
                width: 30,
                height: 30,
                color: primaryColor,
              ),
            ),
          ),
        ));
  }
}
