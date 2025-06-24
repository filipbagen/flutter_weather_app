import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/weather_page.dart';
import 'pages/outfit_page.dart';
import 'pages/about_page.dart';
import 'models/weather_data.dart';

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

  void _updateWeatherData(WeatherData? weatherData) {
    setState(() {
      _sharedWeatherData = weatherData;
    });
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
        currentPage = WeatherPage(onWeatherUpdate: _updateWeatherData);
        break;
      case 1:
        currentPage = OutfitPage(weatherData: _sharedWeatherData);
        break;
      case 2:
        currentPage = const AboutPage();
        break;
      default:
        currentPage = WeatherPage(onWeatherUpdate: _updateWeatherData);
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
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
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
              color: Colors.black.withOpacity(0.1),
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
          ).colorScheme.onSurface.withOpacity(0.6),
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
