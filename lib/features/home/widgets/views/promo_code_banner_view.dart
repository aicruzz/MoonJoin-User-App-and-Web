import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

class PromoCodeShimmerView extends StatelessWidget {
  const PromoCodeShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeSmall),
      child: Column(children: [

        CarouselSlider.builder(
          itemCount: 5,
          options: CarouselOptions(
            height: 135,
            enlargeCenterPage: true,
            disableCenter: true,
            viewportFraction: 0.95,
          ),
          itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
            return Shimmer(
              duration: const Duration(seconds: 2),
              enabled: true,
              child: Container(
                height: 135, width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}
