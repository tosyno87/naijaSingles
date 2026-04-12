import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/utils/remote_image_url.dart';
import '../../../../models/user_model.dart';
import '../../../chat/ui/screens/chat_page.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import 'matches_card.dart';

class MatchDialogPage extends StatefulWidget {
  const MatchDialogPage({
    required this.currentUser,
    required this.matchedUser,
    super.key,
  });
  final UserModel currentUser;
  final UserModel matchedUser;

  @override
  State<MatchDialogPage> createState() => _MatchDialogPageState();
}

class _MatchDialogPageState extends State<MatchDialogPage> {
  String _firstPhotoUrl(UserModel user) {
    final Object? raw = user.imageUrl;
    if (raw is! List || raw.isEmpty) return '';
    return raw.first?.toString() ?? '';
  }

  Widget _buildMatchAvatar(UserModel user, double size) {
    final String url = _firstPhotoUrl(user);
    if (isPlaceholderOrUnreliableImageUrl(url)) {
      return ClipOval(
        child: Container(
          width: size,
          height: size,
          color: Colors.grey.shade400,
          child: Icon(
            Icons.person,
            size: size * 0.45,
            color: Colors.white70,
          ),
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, __) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade400,
          child: Icon(Icons.person, size: size * 0.45, color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xffFEC4E1),
        body: Column(
          children: [
            const SizedBox(
              height: 75,
            ),
            Center(
              child: SizedBox(
                height: 78,
                width: 266,
                child: Text(
                  'It’s a Match'.tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 62,
                    color: const Color(0xffEE193B),
                    fontWeight: FontWeight.w700,
                    fontFamily: GoogleFonts.licorice().fontFamily,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 25,
              child: Text(
                'with ${widget.matchedUser.name}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                ),
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMatchAvatar(widget.currentUser, 150),
                    Padding(
                      padding: const EdgeInsets.only(top: 90),
                      child: _buildMatchAvatar(widget.matchedUser, 160),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Color(0xffFEC4E1),
                        size: 50,
                      ),
                      Icon(
                        Icons.favorite,
                        color: Color(0xffE21F3F),
                        size: 45,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 70,
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chatId(
                          widget.currentUser,
                          widget.matchedUser,
                        ),
                        sender: widget.currentUser,
                        second: widget.matchedUser,
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                width: 241,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  // color: const Color(0xFFDF1D3C),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDF1D3C),
                      Color(0xffEE193B),
                    ],
                    stops: [1.0, 1.0],
                  ),
                ),
                child: Center(
                  child: Text(
                    'Send Message'.tr().toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () {
                context
                    .read<SearchUserBloc>()
                    .add(LoadUserEvent(currentUser: widget.currentUser));
                Navigator.pop(context);
              },
              child: Container(
                width: 241,
                height: 45,
                decoration: BoxDecoration(
                  border: Border.all(
                    strokeAlign: BorderSide.strokeAlignOutside,

                    color: const Color(0xFFFF3A5A), // Border color
                  ),
                  borderRadius: BorderRadius.circular(27),
                  color: const Color(0xFFFFFFFF),
                ),
                child: Center(
                  child: Text(
                    'Keep Swiping'.tr().toString(),
                    style: TextStyle(
                      color: const Color(0xffFD3858),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
