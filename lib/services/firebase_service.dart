import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  static Future<SensorData?> getLatestSensorData() async {
    final url = Uri.parse(
      '${dotenv.env['FIREBASE_URL']}/latest_reading.json?auth=${dotenv.env['FIREBASE_SECRET']}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return SensorData.fromJson(data);
    }
    return null;
  }

  static Future<List<SensorData>> getWeatherHistory({int limit = 20}) async {
    final url = Uri.parse(
      '${dotenv.env['FIREBASE_URL']}/weather_readings.json?auth=${dotenv.env['FIREBASE_SECRET']}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data == null) return [];

      if (data is Map<String, dynamic>) {
        List<SensorData> readings = [];

        for (var entry in data.entries) {
          try {
            final reading = SensorData.fromJson(
              entry.value as Map<String, dynamic>,
            );
            readings.add(reading);
          } catch (e) {
            continue;
          }
        }

        // Sort by timestamp (newest first) and take the requested limit
        readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return readings.take(limit).toList();
      }
    }
    return [];
  }

  // Debug method to test Firebase connection and data structure
  static Future<Map<String, dynamic>?> debugFirebaseData() async {
    final url = Uri.parse(
      '${dotenv.env['FIREBASE_URL']}/weather_readings.json?auth=${dotenv.env['FIREBASE_SECRET']}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>?;
    }
    return null;
  }
}
