import 'package:flutter/cupertino.dart';

abstract class AppPadding {
  static paddingHorizontal16() => EdgeInsets.symmetric(horizontal: 16);

  static paddingHorizontal16Vertical4() => EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      );

  static paddingHorizontal8FromVerticalTop8() => EdgeInsets.only(
        top: 8,
        right: 8,
        left: 8,
      );

  static paddingHorizontal8Vertical4() => EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      );

  static paddingHorizontal30() => EdgeInsets.symmetric(horizontal: 30);

  static paddingHorizontal30Vertical4() =>
      EdgeInsets.symmetric(horizontal: 30, vertical: 4);

  static paddingHorizontal8() => EdgeInsets.symmetric(horizontal: 8);

  static paddingHorizontal16OnlyBottom24() =>
      EdgeInsets.only(right: 16, left: 16, bottom: 24);

  static paddingHorizontal4() => EdgeInsets.symmetric(horizontal: 4);

  static paddingHorizontal2() => EdgeInsets.symmetric(horizontal: 2);

  static paddingAll4() => EdgeInsets.all(4);

  static paddingHorizontal4Vertical8() =>
      EdgeInsets.symmetric(horizontal: 4, vertical: 8);

  static paddingHorizontal4Vertical4() =>
      EdgeInsets.symmetric(horizontal: 4, vertical: 4);

  static paddingHorizontal16Vertical8() =>
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  static paddingHorizontal16Vertical16() =>
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static paddingHorizontal8Vertical8() =>
      EdgeInsets.symmetric(horizontal: 8, vertical: 8);

  static paddingHorizontal16Vertical48() =>
      EdgeInsets.symmetric(horizontal: 16, vertical: 48);

  static paddingVertical25() => EdgeInsets.symmetric(vertical: 25);

  static paddingVertical12Horizontal4() =>
      EdgeInsets.symmetric(vertical: 12, horizontal: 4);

  static paddingVertical8Horizontal4() =>
      EdgeInsets.symmetric(vertical: 8, horizontal: 4);

  static paddingVertical4Horizontal12() =>
      EdgeInsets.symmetric(vertical: 4, horizontal: 12);

  static padding8() => EdgeInsets.all(8);

  static padding12() => EdgeInsets.all(12);

  static padding16Horizontal8Vertical() =>
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  static padding16() => EdgeInsets.all(16);

  static paddingHorizontal16Vertical32() =>
      EdgeInsets.symmetric(horizontal: 16, vertical: 32);

  static paddingHorizontal8Vertical32() =>
      EdgeInsets.symmetric(horizontal: 8, vertical: 32);

  static padding12Horizontal16Vertical() =>
      EdgeInsets.symmetric(horizontal: 12, vertical: 16);

  static padding12Horizontal8Vertical() =>
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  static paddingFromOnlyBottom32() => EdgeInsets.only(bottom: 32);

  static paddingFromOnlyBottom8() => EdgeInsets.only(bottom: 8);

  static paddingZero() => EdgeInsets.zero;

  static paddingVertical32() => EdgeInsets.symmetric(vertical: 32);

  static paddingVertical4() => EdgeInsets.symmetric(vertical: 4);

  static paddingHorizontal24Vertical24() =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 24);

  static paddingHorizontal12Vertical12() =>
      EdgeInsets.symmetric(vertical: 12, horizontal: 12);

  static paddingHorizontal12Vertical8() =>
      EdgeInsets.symmetric(vertical: 8, horizontal: 12);

  static paddingHorizontal12Vertical5() =>
      EdgeInsets.symmetric(vertical: 5, horizontal: 12);

  static paddingHorizontal16Vertical24() =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);
}
