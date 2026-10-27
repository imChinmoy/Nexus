import 'package:intl/intl.dart';

class HeatmapCalendarDay {
  final DateTime date;
  final String dateKey; // YYYY-MM-DD
  final int weekdayIndex; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final int columnIndex; // 0-based week column index

  const HeatmapCalendarDay({
    required this.date,
    required this.dateKey,
    required this.weekdayIndex,
    required this.columnIndex,
  });
}

class HeatmapMonthHeader {
  final String label;
  final int columnIndex;

  const HeatmapMonthHeader({
    required this.label,
    required this.columnIndex,
  });
}

class HeatmapMonthData {
  final int month; // 1 to 12
  final String name; // e.g. "January"
  final String shortName; // e.g. "Jan"
  final int year;
  final int daysInMonth;
  final int startColumnIndex;
  final List<List<HeatmapCalendarDay?>> columns;

  const HeatmapMonthData({
    required this.month,
    required this.name,
    required this.shortName,
    required this.year,
    required this.daysInMonth,
    required this.startColumnIndex,
    required this.columns,
  });
}

class HeatmapCalendarGridData {
  final int year;
  final bool isLeapYear;
  final int totalDays;
  final int totalColumns;

  /// 2D grid: columns[columnIndex][weekdayRowIndex (0..6)]
  final List<List<HeatmapCalendarDay?>> columns;
  final List<HeatmapMonthHeader> monthHeaders;
  final List<HeatmapMonthData> months;

  const HeatmapCalendarGridData({
    required this.year,
    required this.isLeapYear,
    required this.totalDays,
    required this.totalColumns,
    required this.columns,
    required this.monthHeaders,
    this.months = const [],
  });
}

class HeatmapCalendarUtils {
  HeatmapCalendarUtils._();

  static bool isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    return year % 400 == 0;
  }

  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Builds a segregated 12-month calendar grid for the requested [year].
  /// Weekday rows: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat.
  /// Each month is strictly isolated into its own columns without cross-month merging.
  static HeatmapCalendarGridData generateGrid(int year) {
    final leap = isLeapYear(year);
    final totalDays = leap ? 366 : 365;

    final List<HeatmapMonthData> months = [];
    final List<List<HeatmapCalendarDay?>> allColumns = [];
    final List<HeatmapMonthHeader> monthHeaders = [];

    int globalColIndex = 0;

    for (int m = 1; m <= 12; m++) {
      final firstDay = DateTime(year, m, 1);
      final daysInMonth = m == 12
          ? 31
          : DateTime(year, m + 1, 1).subtract(const Duration(days: 1)).day;
      final monthName = DateFormat('MMMM').format(firstDay);
      final shortName = DateFormat('MMM').format(firstDay);

      monthHeaders.add(HeatmapMonthHeader(
        label: shortName,
        columnIndex: globalColIndex,
      ));

      final List<List<HeatmapCalendarDay?>> monthColumns = [];
      List<HeatmapCalendarDay?> currentCol = List.filled(7, null);

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, m, d);
        final weekdayIndex = date.weekday % 7; // 0=Sun, 1=Mon, ..., 6=Sat
        final dateKey = formatDateKey(date);

        final dayData = HeatmapCalendarDay(
          date: date,
          dateKey: dateKey,
          weekdayIndex: weekdayIndex,
          columnIndex: globalColIndex,
        );

        currentCol[weekdayIndex] = dayData;

        // If Saturday (6) is reached or it's the last day of the month
        if (weekdayIndex == 6 || d == daysInMonth) {
          monthColumns.add(currentCol);
          allColumns.add(currentCol);
          globalColIndex++;
          currentCol = List.filled(7, null);
        }
      }

      months.add(HeatmapMonthData(
        month: m,
        name: monthName,
        shortName: shortName,
        year: year,
        daysInMonth: daysInMonth,
        startColumnIndex: globalColIndex - monthColumns.length,
        columns: monthColumns,
      ));
    }

    return HeatmapCalendarGridData(
      year: year,
      isLeapYear: leap,
      totalDays: totalDays,
      totalColumns: allColumns.length,
      columns: allColumns,
      monthHeaders: monthHeaders,
      months: months,
    );
  }
}
