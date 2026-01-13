import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedNetworkImageProviderWidget extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final Widget? widget;

  const CachedNetworkImageProviderWidget(
      {super.key, required this.image, this.widget, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image(
        image: CachedNetworkImageProvider(
      image,
    ));
  }
}
