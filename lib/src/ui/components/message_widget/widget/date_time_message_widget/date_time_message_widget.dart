import 'package:beon_widget_sdk/src/utils/app_colors.dart';
import 'package:flutter/material.dart';


import '../../../../../utils/app_functions/app_functions.dart';

class DateTimeMessageWidget extends StatelessWidget {
  final String dateTime;

  const DateTimeMessageWidget({super.key, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    return Text(

 AppFunctions.convertMessageDateTime(
        date: dateTime,
      ),
      style: TextStyle(
        color: AppColors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w700
      ),
    );
  }
}
