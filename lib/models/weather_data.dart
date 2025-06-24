class WeatherData {
  final String cityName;
  final double temperature;
  final String description;
  final String mainWeather;
  final double feelsLike;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.mainWeather,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? 'Unknown Location',
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      mainWeather: json['weather'][0]['main'],
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  // Convert temperature from Kelvin to Celsius
  double get temperatureCelsius => temperature - 273.15;
  double get feelsLikeCelsius => feelsLike - 273.15;
}
