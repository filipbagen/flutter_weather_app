import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import '../models/forecast_data.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _locationMessage = "Getting location...";
  double? _latitude;
  double? _longitude;
  WeatherData? _weatherData;
  ForecastData? _forecastData;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Location services are disabled.';
      });
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Location permissions are denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = 'Location permissions are permanently denied.';
      });
      return;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = 'Location found!';
      });

      // Fetch weather data after getting location
      _fetchWeatherData();
    } catch (e) {
      setState(() {
        _locationMessage = 'Error getting location: $e';
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_latitude == null || _longitude == null) return;

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final weatherData = await WeatherService.getCurrentWeather(
        _latitude!,
        _longitude!,
      );
      final forecastData = await WeatherService.getForecast(
        _latitude!,
        _longitude!,
      );
      setState(() {
        _weatherData = weatherData;
        _forecastData = forecastData;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching weather: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String weekday = weekdays[date.weekday - 1];
    String month = months[date.month - 1];

    return '$weekday, $month ${date.day}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Current Weather Card (at the top)
          if (_isLoadingWeather)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Loading weather data...'),
                  ],
                ),
              ),
            ),
          if (_weatherData != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _weatherData!.cityName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_weatherData!.temperatureCelsius.round()}°C',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      _weatherData!.description.toUpperCase(),
                      style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Feels like',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text('${_weatherData!.feelsLikeCelsius.round()}°C'),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Humidity',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text('${_weatherData!.humidity}%'),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Wind', style: TextStyle(fontSize: 12)),
                            Text(
                              '${_weatherData!.windSpeed.toStringAsFixed(1)} m/s',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Hourly Forecast (scrollable in the middle)
          if (_forecastData != null)
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hourly Forecast (Next 24h)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _forecastData!.hourlyForecasts.length,
                          itemBuilder: (context, index) {
                            final forecast =
                                _forecastData!.hourlyForecasts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatTime(forecast.date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        forecast.description,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${forecast.temperatureCelsius.round()}°C',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 5-Day Forecast Card (at the bottom)
          if (_forecastData != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '5-Day Forecast',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...(_forecastData!.dailyForecasts.map(
                      (forecast) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatDate(forecast.date),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                forecast.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${forecast.minTemp.round()}° / ${forecast.maxTemp.round()}°',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: const Text('Refresh Location & Weather'),
          ),
        ],
      ),
    );
  }
}
