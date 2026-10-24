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

class HeatmapCalendarGridData {
  final int year;
  final bool isLeapYear;
  final int totalDays;
  final int totalColumns;
  /// 2D grid: columns[columnIndex][weekdayRowIndex (0..6)]
  final List<List<HeatmapCalendarDay?>> columns;
  final List<HeatmapMonthHeader> monthHeaders;

  const HeatmapCalendarGridData({
    required this.year,
    required this.isLeapYear,
    required this.totalDays,
    required this.totalColumns,
    required this.columns,
    required this.monthHeaders,
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

  /// Builds a complete 53-week GitHub-style calendar grid for the requested [year].
  /// Weekday rows: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat.
  static HeatmapCalendarGridData generateGrid(int year) {
    final leap = isLeapYear(year);
    final totalDays = leap ? 366 : 365;

    final List<List<HeatmapCalendarDay?>> columns = [];
    final List<HeatmapMonthHeader> monthHeaders = [];

    final jan1 = DateTime(year, 1, 1);
    final dec31 = DateTime(year, 12, 31);

    int currentColIndex = 0;
    List<HeatmapCalendarDay?> currentCol = List.filled(7, null);

    int lastRecordedMonth = 0;

    DateTime current = jan1;
    while (!current.isAfter(dec31)) {
      // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      final weekdayIndex = current.weekday % 7;

      // When day is the 1st of a month, record month header column
      if (current.month != lastRecordedMonth) {
        lastRecordedMonth = current.month;
        final monthName = DateFormat('MMM').format(current);
        monthHeaders.add(HeatmapMonthHeader(
          label: monthName,
          columnIndex: currentColIndex,
        ));
      }

      final dateKey = formatDateKey(current);
      final dayData = HeatmapCalendarDay(
        date: current,
        dateKey: dateKey,
        weekdayIndex: weekdayIndex,
        columnIndex: currentColIndex,
      );

      currentCol[weekdayIndex] = dayData;

      // If Saturday reached, finalize this column and move to the next
      if (weekdayIndex == 6) {
        columns.add(currentCol);
        currentColIndex++;
        currentCol = List.filled(7, null);
      }

      current = current.add(const Duration(days: 1));
    }

    // If the last column had any days, add it
    if (currentCol.any((d) => d != null)) {
      columns.add(currentCol);
    }

    return HeatmapCalendarGridData(
      year: year,
      isLeapYear: leap,
      totalDays: totalDays,
      totalColumns: columns.length,
      columns: columns,
      monthHeaders: monthHeaders,
    );
  }
}
