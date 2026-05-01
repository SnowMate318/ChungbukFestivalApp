import 'package:intl/intl.dart';

String twoDigits(int n) => n.toString().padLeft(2, '0');

String getCurrency({required num? price}) => (price ?? 0) == 0
    ? '-'
    : '${NumberFormat.simpleCurrency(
        locale: 'ko_KR',
        name: '',
        decimalDigits: 0,
      ).format(price)}원';

String dateTimeToText({required DateTime dateTime}) =>
    '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
