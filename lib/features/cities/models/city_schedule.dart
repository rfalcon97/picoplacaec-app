class DayRuleInfo {
  const DayRuleInfo({required this.weekday, required this.digits});

  final String weekday;
  final List<int> digits;

  factory DayRuleInfo.fromJson(Map<String, dynamic> json) => DayRuleInfo(
        weekday: json['weekday'] as String,
        digits: (json['digits'] as List<dynamic>).map((e) => e as int).toList(),
      );
}

class DateExceptionInfo {
  const DateExceptionInfo({required this.date, required this.reason, required this.restrictionActive});

  final String date;
  final String reason;
  final bool restrictionActive;

  factory DateExceptionInfo.fromJson(Map<String, dynamic> json) => DateExceptionInfo(
        date: json['date'] as String,
        reason: json['reason'] as String,
        restrictionActive: json['restrictionActive'] as bool,
      );
}

class CitySchedule {
  const CitySchedule({
    required this.name,
    required this.allDay,
    required this.timeStart,
    required this.timeEnd,
    required this.dayRules,
    required this.dateExceptions,
  });

  final String name;
  final bool allDay;
  final String? timeStart;
  final String? timeEnd;
  final List<DayRuleInfo> dayRules;
  final List<DateExceptionInfo> dateExceptions;

  factory CitySchedule.fromJson(Map<String, dynamic> json) => CitySchedule(
        name: json['name'] as String,
        allDay: json['allDay'] as bool,
        timeStart: json['timeStart'] as String?,
        timeEnd: json['timeEnd'] as String?,
        dayRules: (json['dayRules'] as List<dynamic>)
            .map((e) => DayRuleInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        dateExceptions: (json['dateExceptions'] as List<dynamic>)
            .map((e) => DateExceptionInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
