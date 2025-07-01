import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  // Stream controller for real-time sensor data updates
  static final StreamController<SensorData?> _sensorDataController =
      StreamController<SensorData?>.broadcast();

  static Stream<SensorData?> get sensorDataStream =>
      _sensorDataController.stream;

  static Timer? _periodicTimer;

  // Start periodic fetching of sensor data
  static void startRealtimeUpdates({
    Duration interval = const Duration(seconds: 30),
  }) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) async {
      final sensorData = await getLatestSensorData();
      _sensorDataController.add(sensorData);
    });

    // Fetch initial data immediately
    getLatestSensorData().then((data) => _sensorDataController.add(data));
  }

  // Stop periodic updates
  static void stopRealtimeUpdates() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // Dispose resources
  static void dispose() {
    stopRealtimeUpdates();
    _sensorDataController.close();
  }

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
}
