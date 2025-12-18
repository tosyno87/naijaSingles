import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/image_widget.dart';

class LargeImage extends StatelessWidget {
  const LargeImage({required this.largeImage, super.key});
  final String largeImage;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,),
        backgroundColor: Theme.of(context).primaryColor,
        body: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),),
                color: Theme.of(context).primaryColor,),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CustomCNImage(
                        main: true,
                        height: MediaQuery.of(context).size.height * .75,
                        width: MediaQuery.of(context).size.width,
                        imageUrl: largeImage,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      FloatingActionButton(
                          heroTag: 'large_image_back_fab',
                          backgroundColor: primaryColor,
                          child: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),),);
}
