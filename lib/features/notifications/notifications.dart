import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../common/bloc/theme/theme_bloc.dart';
import '../../common/constants/colors.dart';
import '../../common/constants/constants.dart';
import '../../common/data/repo/pagination_repo.dart';
import '../../common/data/repo/user_search_repo.dart';
import '../../common/providers/user_provider.dart';
import '../../common/widgets/custom_snackbar.dart';
import '../../common/widgets/hookup_circularbar.dart';
import '../../common/widgets/image_widget.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../user/ui/widgets/user_info.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  NotificationsState createState() => NotificationsState();
}

class NotificationsState extends State<Notifications> {
  final db = firebaseFireStoreInstance;
  late CollectionReference notificationReference;
  UserModel? currentUser;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int perPage = perPageData;
  late DocumentSnapshot? lastVisibleDocument;
  late List<QueryDocumentSnapshot> notifications = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    currentUser = userProvider.currentUser;
    notificationReference =
        db.collection('users').doc(currentUser!.id).collection('Matches');
    _loadInitialNotifications();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent * 0.70 &&
        !_scrollController.position.outOfRange) {
      if (_hasMoreMessages && !_isLoadingMore) {
        log('load more called');
        _loadMoreNotifications();
      }
    }
  }

  void _loadInitialNotifications() {
    final Stream<QuerySnapshot> snapshotStream =
        PaginationRepo.listenForNotifications(perPage, notificationReference);
    snapshotStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          notifications = snapshot.docs;
          _hasMoreMessages = snapshot.docs.length == perPage;
          _isLoadingMore = false;
          lastVisibleDocument =
              snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreNotifications() async {
    setState(() {
      _isLoadingMore = true;
    });
    final snapshot = await PaginationRepo.getMoreNotifications(
      perPage,
      lastVisibleDocument,
      notificationReference,
    );
    setState(() {
      notifications.addAll(snapshot.docs);
      _hasMoreMessages = snapshot.docs.length == perPage;
      _isLoadingMore = false;
      lastVisibleDocument =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Notifications'.tr().toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          color: Theme.of(context).primaryColor,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          child: notifications.isEmpty
              ? Center(
                  child: Text(
                    'No match found'.tr().toString(),
                    style: const TextStyle(
                      color: AppColors.secondaryColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    if (index == notifications.length) {
                      // Last item in the ListView
                      return Column(
                        children: [
                          if (_isLoadingMore)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: Hookup4uBar(),
                            ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      );
                    } else {
                      final doc = notifications[index];
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: !doc.get('isRead')
                                ? isDarkMode
                                    ? Theme.of(context).scaffoldBackgroundColor
                                    : primaryColor.withValues(
                                        alpha: (.15 * 255).toDouble(),
                                      )
                                : isDarkMode
                                    ? Theme.of(context)
                                        .scaffoldBackgroundColor
                                        .withValues(
                                          alpha: (0.70 * 255).toDouble(),
                                        )
                                    : AppColors.secondaryColor.withValues(
                                        alpha: (.15 * 255).toDouble(),
                                      ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(5),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: AppColors.secondaryColor,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: CustomCNImage(
                                  imageUrl: doc.get('pictureUrl') ?? '',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              'you are matched with'.tr().toString(),
                            ).tr(args: ["${doc.get('userName') ?? '__'}"]),
                            subtitle: Text("${doc.get('timestamp').toDate()}"),
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  if (!doc.get('isRead'))
                                    Container(
                                      width: 50,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'NEW'.tr().toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    const Text(''),
                                ],
                              ),
                            ),
                            onTap: () async {
                              log(doc.get('Matches'));
                              showDialog(
                                context: context,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryColor,
                                    ),
                                  ),
                                ),
                              );

                              final DocumentSnapshot userdoc = await db
                                  .collection('users')
                                  .doc(doc.get('Matches'))
                                  .get();
                              if (!context.mounted) return;
                              if (userdoc.exists) {
                                Navigator.pop(context);
                                final UserModel tempuser =
                                    UserModel.fromDocument(userdoc);
                                tempuser.distanceBW =
                                    UserSearchRepo.calculateDistance(
                                  currentUser!.coordinates!['latitude'],
                                  currentUser!.coordinates!['longitude'],
                                  tempuser.coordinates!['latitude'],
                                  tempuser.coordinates!['longitude'],
                                ).round();

                                await showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    if (!doc.get('isRead')) {
                                      PaginationRepo.updateNotification(
                                        currentUser!,
                                        doc,
                                      );
                                    }
                                    return Info(
                                      tempuser,
                                      currentUser!,
                                      false,
                                    );
                                  },
                                );
                              } else {
                                Navigator.pop(context);
                                CustomSnackbar.showSnackBarSimple(
                                  'User does not exist'.tr().toString(),
                                  context,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
        ),
      ),
    );
  }
}
