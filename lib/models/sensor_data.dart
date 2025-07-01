class SensorData {
  final int humidity;
  final String lightLevel;
  final int lightRaw;
  final double temperature;
  final int timestamp;
  final DateTime dateTime;

  SensorData({
    required this.humidity,
    required this.lightLevel,
    required this.lightRaw,
    required this.temperature,
    required this.timestamp,
    required this.dateTime,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'] as int;
    return SensorData(
      humidity: json['humidity'] as int,
      lightLevel: json['light_level'] as String,
      lightRaw: json['light_raw'] as int,
      temperature: (json['temperature'] as num).toDouble(),
      timestamp: timestamp,
      dateTime: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'humidity': humidity,
      'light_level': lightLevel,
      'light_raw': lightRaw,
      'temperature': temperature,
      'timestamp': timestamp,
    };
  }

  // Utility methods
  String get formattedDateTime {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get lightDescription {
    switch (lightLevel) {
      case 'Very Bright':
        return 'Very bright outdoor lighting';
      case 'Bright':
        return 'Bright indoor/outdoor lighting';
      case 'Dim':
        return 'Dim indoor lighting';
      case 'Dark':
        return 'Low light conditions';
      default:
        return lightLevel;
    }
  }

  // Compare with API weather data
  double get temperatureDifference {
    // This will be used to compare with API temperature
    return temperature;
  }

  bool get isDataFresh {
    final now = DateTime.now();
    final dataAge = now.difference(dateTime);
    return dataAge.inMinutes <
        30; // Consider data fresh if less than 30 minutes old
  }
}
