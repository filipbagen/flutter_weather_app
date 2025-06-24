# Flutter Weather App

A Flutter weather application with AI-powered outfit recommendations.

## Features

- **Real-time Weather**: Get current weather data and 5-day forecast using your location
- **AI Outfit Recommendations**: Personalized clothing suggestions based on current weather conditions
- **Beautiful UI**: Modern Material Design 3 interface with smooth animations
- **Location-based**: Automatically detects your location for accurate weather data

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
flutter pub get
```

### 2. Set up API Keys

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Get your API keys:

   - **OpenWeather API**: Sign up at [openweathermap.org](https://openweathermap.org/api) for a free API key
   - **OpenRouter API**: Get your API key at [openrouter.ai](https://openrouter.ai) for AI-powered outfit recommendations

3. Add your API keys to the `.env` file:
   ```
   OPEN_WEATHER_API_KEY=your_actual_openweather_key
   OPENROUTER_API_KEY=your_actual_openrouter_key
   ```

### 3. Run the App

```bash
flutter run
```

## App Structure

- `lib/pages/weather_page.dart` - Main weather display with current conditions and forecast
- `lib/pages/outfit_page.dart` - AI-powered outfit recommendations
- `lib/services/weather_service.dart` - OpenWeather API integration
- `lib/services/ai_service.dart` - OpenAI API integration for outfit suggestions
- `lib/models/` - Data models for weather and forecast data

## Permissions

The app requires location permissions to provide accurate weather data for your current location.

## Getting Started with Flutter

This project is a great starting point for learning Flutter development:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
