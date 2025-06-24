class ForecastItem {
  final DateTime date;
  final double temperatureCelsius;
  final String description;
  final String icon;

  ForecastItem({
    required this.date,
    required this.temperatureCelsius,
    required this.description,
    required this.icon,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperatureCelsius: (json['main']['temp'] - 273.15),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
    );
  }
}

class DailyForecast {
  final DateTime date;
  final String description;
  final double minTemp;
  final double maxTemp;
  final String icon;

  DailyForecast({
    required this.date,
    required this.description,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
  });
}

class ForecastData {
  final List<ForecastItem> items;

  ForecastData({required this.items});

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    List<ForecastItem> items = [];
    for (var item in json['list']) {
      items.add(ForecastItem.fromJson(item));
    }
    return ForecastData(items: items);
  }

  // Get next 8 hourly forecasts (24 hours worth)
  List<ForecastItem> get hourlyForecasts {
    return items.take(8).toList();
  }

  // Get daily forecasts with min/max temperatures
  List<DailyForecast> get dailyForecasts {
    Map<String, List<ForecastItem>> groupedByDay = {};

    for (var item in items) {
      String dateKey = '${item.date.year}-${item.date.month}-${item.date.day}';
      if (!groupedByDay.containsKey(dateKey)) {
        groupedByDay[dateKey] = [];
      }
      groupedByDay[dateKey]!.add(item);
    }

    List<DailyForecast> dailyForecasts = [];

    for (var entry in groupedByDay.entries.take(5)) {
      List<ForecastItem> dayItems = entry.value;

      // Find min and max temperatures for the day
      double minTemp = dayItems
          .map((item) => item.temperatureCelsius)
          .reduce((a, b) => a < b ? a : b);
      double maxTemp = dayItems
          .map((item) => item.temperatureCelsius)
          .reduce((a, b) => a > b ? a : b);

      // Use the first item's description, date, and icon
      dailyForecasts.add(
        DailyForecast(
          date: dayItems.first.date,
          description: dayItems.first.description,
          minTemp: minTemp,
          maxTemp: maxTemp,
          icon: dayItems.first.icon,
        ),
      );
    }

    return dailyForecasts;
  }
}
