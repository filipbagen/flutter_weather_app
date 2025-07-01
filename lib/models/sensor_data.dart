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

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  String get formattedTime =>
      '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  String get formattedDate => '${dateTime.day}/${dateTime.month}';
}
