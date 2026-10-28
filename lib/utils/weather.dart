import 'dart:convert';

import 'package:http/http.dart' as http;

class Weather {
  const Weather({required this.temperature, required this.humidity, required this.description});

  final double temperature;
  final int humidity;
  final String description;
}

Future<Weather> fetchKigaliWeather() async {
  final uri = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=-1.9441&longitude=30.0619'
    '&current=temperature_2m,relative_humidity_2m,weather_code'
    '&timezone=Africa%2FKigali',
  );
  final response = await http.get(uri).timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw Exception('Weather server returned ${response.statusCode}');
  }
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final current = data['current'] as Map<String, dynamic>;
  final code = (current['weather_code'] as num).toInt();
  return Weather(
    temperature: (current['temperature_2m'] as num).toDouble(),
    humidity: (current['relative_humidity_2m'] as num).toInt(),
    description: describeWeather(code),
  );
}

String describeWeather(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 2) return 'Partly cloudy';
  if (code == 3) return 'Cloudy';
  if (code == 45 || code == 48) return 'Fog';
  if (code >= 51 && code <= 57) return 'Drizzle';
  if (code >= 61 && code <= 67) return 'Rain';
  if (code >= 80 && code <= 82) return 'Rain showers';
  if (code >= 95) return 'Thunderstorm';
  return 'Unknown';
}
