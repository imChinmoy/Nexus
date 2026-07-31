import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String get capitalize =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : this;

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isValidEmail => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(this);

  bool get isValidPhone => RegExp(r'^[0-9]{10}$').hasMatch(this);

  bool get isValidRollNumber => RegExp(r'^[0-9]{2}[A-Z]{2}[0-9]{5}$').hasMatch(this);
}

extension DateTimeExtension on DateTime {
  String get formatted => DateFormat('dd MMM yyyy').format(this);
  String get formattedFull => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get timeOnly => DateFormat('hh:mm a').format(this);
  String get dayMonth => DateFormat('dd MMM').format(this);
  String get monthYear => DateFormat('MMM yyyy').format(this);
  String get iso => toIso8601String();

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF4444) : const Color(0xFF00FF88),
      ),
    );
  }

  void pop([dynamic result]) => Navigator.of(this).pop(result);
}

extension IntExtension on int {
  String get withCommas => NumberFormat('#,###').format(this);
  String get percentage => '$this%';
}

extension DoubleExtension on double {
  String get percentage => '${toStringAsFixed(1)}%';
  String get formatted => NumberFormat('#,###.##').format(this);
}
