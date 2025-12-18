import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import '../constants/adds.dart';
import '../constants/colors.dart';

class CarouselSlider extends StatefulWidget {

  const CarouselSlider({required this.adds, super.key});
  final List<Map<String, dynamic>> adds;

  @override
  // ignore: library_private_types_in_public_api
  _CarouselSliderState createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider> {
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          height: 100,
          width: MediaQuery.of(context).size.width * .85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Swiper(
              key: UniqueKey(),
              curve: Curves.linear,
              autoplay: true,
              physics: const ScrollPhysics(),
              itemBuilder: (BuildContext context, int index2) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            adds[index2]['icon'],
                            color: adds[index2]['color'],
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: Text(
                              adds[index2]['title'],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold,),
                            ).tr(),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          adds[index2]['subtitle'],
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ).tr(),
                      ),
                    ],),
              itemCount: adds.length,
              pagination: const SwiperPagination(
                  alignment: Alignment.bottomCenter,
                  builder: DotSwiperPaginationBuilder(
                      color: AppColors.secondaryColor,
                      activeColor: primaryColor,),),
              control: const SwiperControl(
                size: 20,
                color: primaryColor,
                disableColor: AppColors.secondaryColor,
              ),
              loop: false,
            ),
          ),
        ),
      ),
    );
}
