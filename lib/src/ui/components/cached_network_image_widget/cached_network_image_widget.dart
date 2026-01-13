import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final Widget? widget;
  final bool isCircle;
  final double radius;
  final bool isProfile;
  final bool isTeacher;

  const CachedNetworkImageWidget({
    super.key,
    required this.image,
    this.widget,
    this.width,
    this.height,
    this.isCircle = false,
    this.isProfile = false,
    this.isTeacher = false,
    this.radius = 38,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) => isCircle
          ? CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
            )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  fit: BoxFit.contain,
                  image: imageProvider,
                ),
              ),
              child: widget,
            ),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade400,
        highlightColor: Colors.grey,
        child: isCircle
            ? isProfile
                ? CircleAvatar(
                    radius: radius,
                  )
                : CircleAvatar(
                    radius: radius,
                  )
            : Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
      ),
      errorWidget: (context, url, error) => isCircle
          ? isProfile
              ? CircleAvatar(
                  radius: radius,
                  child: Icon(Icons.error),
                )
              : CircleAvatar(
                  radius: radius,
                  child: Icon(Icons.error),
                )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.error),
            ),
    );
  }
}
