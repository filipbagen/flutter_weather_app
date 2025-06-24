import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import '../models/forecast_data.dart';

class WeatherPage extends StatefulWidget {
  final Function(WeatherData?, ForecastData?)? onWeatherUpdate;
  final WeatherData? weatherData;
  final ForecastData? forecastData;
  final bool isLoading;
  final Function(bool)? onLoadingChanged;

  const WeatherPage({
    super.key,
    this.onWeatherUpdate,
    this.weatherData,
    this.forecastData,
    this.isLoading = false,
    this.onLoadingChanged,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    // Only fetch weather if we don't have data yet
    if (widget.weatherData == null) {
      _getCurrentLocation();
    }
  }

  // Getter methods to use either shared data or show appropriate states
  WeatherData? get _weatherData => widget.weatherData;
  ForecastData? get _forecastData => widget.forecastData;

  // Manual refresh function
  Future<void> _refreshWeather() async {
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services disabled - could show a snackbar here if needed
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Location permissions denied - could show a snackbar here if needed
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Location permissions permanently denied - could show a snackbar here if needed
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      _fetchWeatherData();
    } catch (e) {
      // Error getting location - could show a snackbar here if needed
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_latitude == null || _longitude == null) return;

    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(true);
    }

    try {
      final weatherData = await WeatherService.getCurrentWeather(
        _latitude!,
        _longitude!,
      );
      final forecastData = await WeatherService.getForecast(
        _latitude!,
        _longitude!,
      );

      // Notify parent widget about weather data update
      if (widget.onWeatherUpdate != null) {
        widget.onWeatherUpdate!(weatherData, forecastData);
      }

      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
    } catch (e) {
      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching weather: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return weekdays[date.weekday % 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Current Weather - Hero Card
              if (_weatherData != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              _weatherData!.cityName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://openweathermap.org/img/wn/${_weatherData!.icon}@4x.png',
                                  width: 120,
                                  height: 120,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.wb_sunny,
                                      size: 120,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  children: [
                                    Text(
                                      '${_weatherData!.temperatureCelsius.round()}°',
                                      style: TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w200,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      'Celsius',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _weatherData!.description.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Hourly Forecast
              if (_forecastData != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hourly Forecast',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _forecastData!.hourlyForecasts.length,
                              itemBuilder: (context, index) {
                                final forecast =
                                    _forecastData!.hourlyForecasts[index];
                                final isNow = index == 0;
                                return Container(
                                  width: 85,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Card(
                                    elevation: isNow ? 6 : 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: isNow
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.3),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isNow
                                                ? 'Now'
                                                : '${forecast.date.hour}:00',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isNow
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Image.network(
                                            'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                                            width: 32,
                                            height: 32,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.wb_sunny,
                                                    size: 32,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  );
                                                },
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${forecast.temperatureCelsius.round()}°',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isNow
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            ),
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
                ),

              // Daily Forecast
              if (_forecastData != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '5-Day Forecast',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: _forecastData!.dailyForecasts.map((
                              forecast,
                            ) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatDate(forecast.date),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Image.network(
                                            'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                                            width: 32,
                                            height: 32,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.wb_sunny,
                                                    size: 32,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  );
                                                },
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              forecast.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${forecast.minTemp.round()}° / ${forecast.maxTemp.round()}°',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Pull to refresh hint
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
