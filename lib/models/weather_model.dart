import 'package:flutter/material.dart';

class WeatherModel {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String description;
  final String mainCondition;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;
  final int sunrise;
  final int sunset;
  final DateTime dateTime;

  WeatherModel({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.dateTime,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      country: json['sys']?['country'] ?? '',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']?['feels_like'] ?? 0).toDouble(),
      tempMin: (json['main']?['temp_min'] ?? 0).toDouble(),
      tempMax: (json['main']?['temp_max'] ?? 0).toDouble(),
      description: json['weather']?[0]?['description'] ?? '',
      mainCondition: json['weather']?[0]?['main'] ?? '',
      iconCode: json['weather']?[0]?['icon'] ?? '01d',
      humidity: json['main']?['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      pressure: json['main']?['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      sunrise: json['sys']?['sunrise'] ?? 0,
      sunset: json['sys']?['sunset'] ?? 0,
      dateTime: DateTime.now(),
    );
  }

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@4x.png';

  // ============ Theme Helpers ============

  bool get isNight => iconCode.contains('n');

  bool get isRainy {
    final d = mainCondition.toLowerCase();
    return d.contains('rain') ||
        d.contains('drizzle') ||
        d.contains('thunder');
  }

  bool get isCloudy => mainCondition.toLowerCase().contains('cloud');

  bool get isSnowy => mainCondition.toLowerCase().contains('snow');

  bool get isClear => mainCondition.toLowerCase().contains('clear');

  bool get isMist {
    final d = mainCondition.toLowerCase();
    return d.contains('mist') ||
        d.contains('fog') ||
        d.contains('haze');
  }

  // Primary gradient — aurora style premium colors
  List<Color> get gradientColors {
    if (isNight) {
      return const [
        Color(0xFF0B1026),
        Color(0xFF1B2A4E),
        Color(0xFF2C3E68),
      ];
    }
    if (isRainy) {
      return const [
        Color(0xFF1F2B45),
        Color(0xFF324A6E),
        Color(0xFF4B6C93),
      ];
    }
    if (isSnowy) {
      return const [
        Color(0xFF7B9ECC),
        Color(0xFFA8C6E8),
        Color(0xFFD9E8F5),
      ];
    }
    if (isCloudy) {
      return const [
        Color(0xFF485563),
        Color(0xFF6B7A8F),
        Color(0xFF8E9BAB),
      ];
    }
    if (isMist) {
      return const [
        Color(0xFF606C88),
        Color(0xFF7B8AA0),
        Color(0xFF95A3B8),
      ];
    }
    if (isClear && isNight) {
      return const [
        Color(0xFF141E30),
        Color(0xFF243B55),
        Color(0xFF2C5364),
      ];
    }
    // Default clear day — premium aurora blue
    return const [
      Color(0xFF2E3192),
      Color(0xFF1BFFFF),
      Color(0xFF2E3192),
    ];
  }

  // Accent color for glow / highlights
  Color get accentColor {
    if (isNight) return const Color(0xFF6C8BFF);
    if (isRainy) return const Color(0xFF6BA8FF);
    if (isSnowy) return const Color(0xFFE0F0FF);
    if (isCloudy) return const Color(0xFFB0C4DE);
    if (isClear) return const Color(0xFFFFD86F);
    return const Color(0xFF9BC5FF);
  }
}