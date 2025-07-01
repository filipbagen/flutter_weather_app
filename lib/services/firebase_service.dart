import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  static String get _firebaseUrl {
    final url = dotenv.env['FIREBASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('Firebase URL not found in .env file');
    }
    return url;
  }

  static String get _firebaseSecret {
    final secret = dotenv.env['FIREBASE_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('Firebase secret not found in .env file');
    }
    return secret;
  }

  /// Fetches the latest sensor reading from Firebase Realtime Database
  static Future<SensorData?> getLatestSensorData() async {
    try {
      final url = Uri.parse(
        '$_firebaseUrl/latest_reading.json?auth=$_firebaseSecret',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data == null) {
          print('No sensor data found in Firebase');
          return null;
        }

        // Handle the case where data is a Map
        if (data is Map<String, dynamic>) {
          return SensorData.fromJson(data);
        } else {
          print('Unexpected data format from Firebase: ${data.runtimeType}');
          return null;
        }
      } else {
        throw Exception('Failed to fetch sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sensor data from Firebase: $e');
      throw Exception('Error fetching sensor data: $e');
    }
  }

  /// Fetches historical sensor data (optional for future use)
  static Future<List<SensorData>> getHistoricalSensorData({
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        '$_firebaseUrl/historical_readings.json?auth=$_firebaseSecret&orderBy="\$key"&limitToLast=$limit',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data == null) {
          return [];
        }

        if (data is Map<String, dynamic>) {
          return data.entries
              .map(
                (entry) =>
                    SensorData.fromJson(entry.value as Map<String, dynamic>),
              )
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to fetch historical sensor data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching historical sensor data from Firebase: $e');
      return [];
    }
  }

  /// Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse(
        '$_firebaseUrl/.json?auth=$_firebaseSecret&shallow=true',
      );
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  /// Listen to real-time updates (using HTTP polling since we're using REST API)
  /// For true real-time updates, you'd want to use Firebase SDK with WebSocket support
  static Stream<SensorData?> listenToSensorData({
    Duration interval = const Duration(seconds: 30),
  }) {
    return Stream.periodic(interval, (_) async {
      try {
        return await getLatestSensorData();
      } catch (e) {
        print('Error in sensor data stream: $e');
        return null;
      }
    }).asyncMap((future) => future);
  }
}
