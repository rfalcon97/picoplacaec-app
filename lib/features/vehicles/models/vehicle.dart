import '../../cities/models/city.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.nickname,
    required this.plateDigit,
    required this.reminderTime,
    required this.city,
  });

  final String id;
  final String nickname;
  final int plateDigit;
  final String reminderTime;
  final City city;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        plateDigit: json['plateDigit'] as int,
        reminderTime: json['reminderTime'] as String,
        city: City.fromJson(json['city'] as Map<String, dynamic>),
      );
}
