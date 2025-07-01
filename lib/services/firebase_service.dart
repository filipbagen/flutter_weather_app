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
}
