import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_data.dart';
import '../models/forecast_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static String get _apiKey {
    final key = dotenv.env['OPEN_WEATHER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('API key not found in .env file');
    }
    return key;
  }

  static Future<WeatherData> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  static Future<ForecastData> getForecast(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ForecastData.fromJson(data);
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }
}
