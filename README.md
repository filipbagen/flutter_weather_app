# IoT Weather App

A simple Flutter app that shows live sensor data from IoT devices and provides AI-powered outfit recommendations.

## Features

- **Live Sensor Data**: Real-time temperature, humidity, and light level from IoT sensors
- **Weather Charts**: Historical data visualization with beautiful charts
- **AI Outfit Suggestions**: Smart clothing recommendations based on current conditions
- **Clean Design**: Simple, modern interface that's easy to use

## Quick Setup

1. **Install Flutter dependencies**:

   ```bash
   flutter pub get
   ```

2. **Add your API keys** to `.env` file:

   ```
   FIREBASE_URL=your_firebase_database_url
   FIREBASE_SECRET=your_firebase_secret
   OPEN_WEATHER_API_KEY=your_weather_api_key
   OPENROUTER_API_KEY=your_ai_api_key
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## How It Works

The app connects to Firebase Realtime Database to get live sensor readings from IoT devices. It displays this data in a beautiful interface and uses AI to suggest appropriate clothing based on the current conditions.

Perfect for learning Flutter, Firebase, and IoT integration!
