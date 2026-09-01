class DayStatus {
  const DayStatus({
    required this.date,
    required this.restricted,
    required this.allDay,
    required this.timeStart,
    required this.timeEnd,
    required this.reason,
  });

  final String date;
  final bool restricted;
  final bool allDay;
  final String? timeStart;
  final String? timeEnd;
  final String reason;

  factory DayStatus.fromJson(Map<String, dynamic> json) => DayStatus(
        date: json['date'] as String,
        restricted: json['restricted'] as bool,
        allDay: json['allDay'] as bool,
        timeStart: json['timeStart'] as String?,
        timeEnd: json['timeEnd'] as String?,
        reason: json['reason'] as String,
      );
}

class VehicleStatus {
  const VehicleStatus({
    required this.vehicleId,
    required this.nickname,
    required this.plateDigit,
    required this.reminderTime,
    required this.today,
    required this.nextRestrictedDate,
    required this.cityId,
    required this.citySlug,
    required this.cityName,
  });

  final String vehicleId;
  final String nickname;
  final int plateDigit;
  final String reminderTime;
  final DayStatus today;
  final String? nextRestrictedDate;
  final String cityId;
  final String citySlug;
  final String cityName;

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>;
    return VehicleStatus(
      vehicleId: json['vehicleId'] as String,
      nickname: json['nickname'] as String,
      plateDigit: json['plateDigit'] as int,
      reminderTime: json['reminderTime'] as String,
      today: DayStatus.fromJson(json['today'] as Map<String, dynamic>),
      nextRestrictedDate: json['nextRestrictedDate'] as String?,
      cityId: city['id'] as String,
      citySlug: city['slug'] as String,
      cityName: city['name'] as String,
    );
  }
}
