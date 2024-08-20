import 'package:flutter/material.dart';
import 'package:hookup4u2/features/blockUser/screen/block_userlist.dart';

import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';
import '../../../../common/constants/colors.dart';

import 'package:easy_localization/easy_localization.dart';

import '../../../../common/providers/user_provider.dart';
import '../../../chat/ui/widgets/recent_chats.dart';

import '../widget/matches_card.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  MatchScreenState createState() => MatchScreenState();
}

class MatchScreenState extends State<MatchScreen> {
  UserModel? currentUser;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    currentUser = userProvider.currentUser;
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Messages'.tr().toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        elevation: 0.0,
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                color: Theme.of(context).primaryColor),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Matches(
                      currentUser: currentUser!,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).primaryColor,
              child: DefaultTabController(
                length: 2,
                initialIndex: 0,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: primaryColor,
                      indicatorColor: secondryColor,
                      indicatorWeight: 1.0,
                      unselectedLabelColor: secondryColor,
                      isScrollable: false,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(
                          child: Text(
                            'Recent Messages'.tr().toString(),
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Blocked Matches'.tr().toString(),
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          RecentChats(
                            currentUser: currentUser!,
                            scrollController: _scrollController,
                          ),
                          BlockedUser(
                            currentUser: currentUser!,
                            scrollController: _scrollController,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
