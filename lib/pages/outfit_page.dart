import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/outfit_data.dart';

class OutfitPage extends StatefulWidget {
  final WeatherData? weatherData;
  final OutfitData? outfitRecommendation;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const OutfitPage({
    super.key,
    this.weatherData,
    this.outfitRecommendation,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            widget.onRefresh!();
            // Add a small delay to show the refresh indicator
            await Future.delayed(const Duration(milliseconds: 500));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Single Combined Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
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
                          ).colorScheme.primaryContainer.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        children: [
                          // Header Section
                          Text(
                            'AI Outfit Assistant',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Content based on state
                          if (widget.weatherData == null)
                            _buildNoWeatherContent()
                          else if (widget.isLoading)
                            _buildLoadingContent()
                          else if (widget.outfitRecommendation != null)
                            _buildRecommendationContent()
                          else
                            _buildErrorContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.weatherData == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Get weather data from the Weather tab first',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
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

  Widget _buildNoWeatherContent() {
    return Column(
      children: [
        Icon(
          Icons.wb_sunny_outlined,
          size: 64,
          color: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 16),
        Text(
          'No weather data available',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Please visit the Weather tab to load current weather conditions first.',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        CircularProgressIndicator(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          strokeWidth: 3,
        ),
        const SizedBox(height: 20),
        Text(
          'Getting your personalized outfit recommendation...',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendationContent() {
    return Column(
      children: [
        // Visual Outfit Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          // ),
          child: Column(
            children: [
              // Outfit Visualization
              _buildOutfitVisualization(),

              const SizedBox(height: 20),

              // AI Motivation
              _buildMotivationText(),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_downward,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutfitVisualization() {
    final outfit = widget.outfitRecommendation!;

    return SizedBox(
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom layer: Shoes (at the very bottom)
          if (outfit.shoes != null)
            Positioned(
              bottom: 0,
              child: Image.asset(
                'lib/assets/images/clothing/shoes/${outfit.shoes}.png',
                height: 35, // Reduced from 60 to 40
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 30, // Reduced from 60 to 40
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.hiking, color: Colors.brown),
                  );
                },
              ),
            ),

          // Second layer: Pants/Bottoms (directly above shoes)
          if (outfit.bottom != null)
            Positioned(
              bottom: 35, // Adjusted from 60 to 40 to match new shoe height
              child: Image.asset(
                'lib/assets/images/clothing/bottoms/${outfit.bottom}.png',
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.checkroom, color: Colors.green),
                  );
                },
              ),
            ),

          // Third layer: Top/Shirt (directly above pants)
          if (outfit.top != null)
            Positioned(
              bottom: 180, // Adjusted from 160 to 140 (40 + 100)
              child: Image.asset(
                'lib/assets/images/clothing/tops/${outfit.top}.png',
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.checkroom, color: Colors.blue),
                  );
                },
              ),
            ),

          // Top layer: Accessory (head, glasses, cap, etc.)
          if (outfit.accessory != null)
            Positioned(
              bottom: 285, // Adjusted from 280 to 260 (40 + 100 + 120)
              child: Image.asset(
                'lib/assets/images/clothing/accessories/${outfit.accessory}.png',
                height: 65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: Colors.grey),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMotivationText() {
    final outfit = widget.outfitRecommendation!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outfit.motivation ?? 'Perfect outfit for today\'s weather!',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to get outfit recommendation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
