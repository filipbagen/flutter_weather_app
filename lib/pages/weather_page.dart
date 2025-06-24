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

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Location services are disabled.';
      });
      return;
    }

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

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = 'Location found!';
      });

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching weather: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _getCurrentLocation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Weather
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://openweathermap.org/img/wn/${_weatherData!.icon}@2x.png',
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.wb_sunny,
                                size: 80,
                                color: Colors.orange,
                              );
                            },
                          ),
                          Text(
                            '${_weatherData!.temperatureCelsius.round()}°C',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _weatherData!.description.toUpperCase(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Hourly Forecast
            if (_forecastData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hourly Forecast',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _forecastData!.hourlyForecasts.length,
                          itemBuilder: (context, index) {
                            final forecast =
                                _forecastData!.hourlyForecasts[index];
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${forecast.date.hour}:00',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${forecast.temperatureCelsius.round()}°C',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        forecast.description,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
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

            const SizedBox(height: 16),

            // Daily Forecast
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
                      Column(
                        children: _forecastData!.dailyForecasts.map((forecast) {
                          return ListTile(
                            title: Text(
                              '${forecast.date.month}/${forecast.date.day}',
                            ),
                            subtitle: Text(forecast.description),
                            trailing: Text(
                              '${forecast.minTemp.round()}°/${forecast.maxTemp.round()}°C',
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
            // Hint text for pull-to-refresh
            const Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
