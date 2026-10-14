import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';


class WeatherService {

  static final String _apiKey = dotenv.get('WEATHER_API_KEY');
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherModel> getWeatherByCity(String city) async {
    final url = Uri.parse(
      '$_baseUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric',
    );
    return _fetchWeather(url);
  }

  Future<WeatherModel> getWeatherByLocation(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
    );
    return _fetchWeather(url);
  }

  Future<WeatherModel> _fetchWeather(Uri url) async {
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('City not found! Please check the city name and try again.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API Key or API Key not activated!');
      } else {
        throw Exception('Error fetching weather data (${response.statusCode})');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}