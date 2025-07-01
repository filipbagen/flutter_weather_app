class SensorData {
  final int humidity;
  final String lightLevel;
  final double temperature;
  final int timestamp;

  SensorData({
    required this.humidity,
    required this.lightLevel,
    required this.temperature,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      humidity: json['humidity'] as int,
      lightLevel: json['light_level'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      timestamp: json['timestamp'] as int,
    );
  }
}
