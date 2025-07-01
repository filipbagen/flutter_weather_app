import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/weather_page_wrapper.dart';
import 'pages/outfit_page.dart';
import 'pages/about_page.dart';
import 'models/weather_data.dart';
import 'models/forecast_data.dart';
import 'models/outfit_data.dart';
import 'models/sensor_data.dart';
import 'services/ai_service.dart';
import 'services/firebase_service.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      themeMode: ThemeMode.system,
      home: const BottomNavigationBarExample(),
    );
  }
}

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;
  WeatherData? _sharedWeatherData;
  ForecastData? _sharedForecastData;
  SensorData? _sharedSensorData;
  OutfitData? _outfitRecommendation;
  bool _isLoadingOutfit = false;
  bool _isLoadingWeather = false;

  void _updateWeatherData(
    WeatherData? weatherData,
    ForecastData? forecastData,
  ) async {
    setState(() {
      _sharedWeatherData = weatherData;
      _sharedForecastData = forecastData;
    });

    // If we have new weather data and no recommendation yet, get one
    // Prioritize sensor data if available, otherwise use API data
    if ((weatherData != null || _sharedSensorData != null) &&
        _outfitRecommendation == null) {
      await _getOutfitRecommendation();
    }
  }

  void _updateSensorData(SensorData? sensorData) async {
    setState(() {
      _sharedSensorData = sensorData;
    });

    // If we have new sensor data, refresh the outfit recommendation
    if (sensorData != null) {
      await _getOutfitRecommendation();
    }
  }

  void _setWeatherLoading(bool loading) {
    setState(() {
      _isLoadingWeather = loading;
    });
  }

  Future<void> _getOutfitRecommendation() async {
    // Prioritize sensor data if available, otherwise use API data
    if (_sharedSensorData == null && _sharedWeatherData == null) return;

    setState(() {
      _isLoadingOutfit = true;
    });

    try {
      OutfitData recommendation;

      if (_sharedSensorData != null) {
        // Use sensor data for AI recommendation (prioritized)
        recommendation = await AIService.getOutfitRecommendationFromSensor(
          _sharedSensorData!,
        );
      } else {
        // Fallback to weather API data
        recommendation = await AIService.getOutfitRecommendation(
          _sharedWeatherData!,
        );
      }

      setState(() {
        _outfitRecommendation = recommendation;
        _isLoadingOutfit = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOutfit = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting outfit recommendation: $e')),
        );
      }
    }
  }

  void _refreshOutfitRecommendation() {
    setState(() {
      _outfitRecommendation = null;
    });
    _getOutfitRecommendation();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    late Widget currentPage;

    switch (_selectedIndex) {
      case 0:
        currentPage = WeatherPageWrapper(
          onWeatherUpdate: _updateWeatherData,
          onSensorUpdate: _updateSensorData,
          weatherData: _sharedWeatherData,
          forecastData: _sharedForecastData,
          isLoading: _isLoadingWeather,
          onLoadingChanged: _setWeatherLoading,
        );
        break;
      case 1:
        currentPage = OutfitPage(
          weatherData: _sharedWeatherData,
          sensorData: _sharedSensorData,
          outfitRecommendation: _outfitRecommendation,
          isLoading: _isLoadingOutfit,
          onRefresh: _refreshOutfitRecommendation,
        );
        break;
      case 2:
        currentPage = const AboutPage();
        break;
      default:
        currentPage = WeatherPageWrapper(
          onWeatherUpdate: _updateWeatherData,
          onSensorUpdate: _updateSensorData,
          weatherData: _sharedWeatherData,
          forecastData: _sharedForecastData,
          isLoading: _isLoadingWeather,
          onLoadingChanged: _setWeatherLoading,
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: currentPage,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: 'Weather',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom_outlined),
              activeIcon: Icon(Icons.checkroom),
              label: 'Outfit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outlined),
              activeIcon: Icon(Icons.info),
              label: 'About',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
