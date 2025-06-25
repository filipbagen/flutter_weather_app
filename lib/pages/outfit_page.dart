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
      child: SingleChildScrollView(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'AI Outfit Assistant',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            if (!widget.isLoading &&
                                widget.outfitRecommendation != null &&
                                widget.weatherData != null)
                              IconButton(
                                onPressed: widget.onRefresh,
                                icon: Icon(
                                  Icons.refresh,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                tooltip: 'Get new recommendation',
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.3),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Recommended Outfit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),

              // Outfit Visualization
              _buildOutfitVisualization(),

              const SizedBox(height: 20),

              // Outfit Details
              _buildOutfitDetails(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Tap refresh for a different suggestion',
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

    return Container(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background figure
          if (outfit.accessory != null && outfit.accessory!.contains('head'))
            Positioned(
              top: 0,
              child: Image.asset(
                'lib/assets/images/clothing/accessories/${outfit.accessory}.png',
                height: 80,
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

          // Top clothing
          if (outfit.top != null)
            Positioned(
              top: 60,
              child: Image.asset(
                'lib/assets/images/clothing/tops/${outfit.top}.png',
                height: 120,
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

          // Bottom clothing
          if (outfit.bottom != null)
            Positioned(
              top: 160,
              child: Image.asset(
                'lib/assets/images/clothing/bottoms/${outfit.bottom}.png',
                height: 100,
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

          // Shoes
          if (outfit.shoes != null)
            Positioned(
              bottom: 0,
              child: Image.asset(
                'lib/assets/images/clothing/shoes/${outfit.shoes}.png',
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 60,
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

          // Accessories (glasses, etc.)
          if (outfit.accessory != null && outfit.accessory!.contains('glasses'))
            Positioned(
              top: 30,
              child: Image.asset(
                'lib/assets/images/clothing/accessories/${outfit.accessory}.png',
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 40,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.visibility, color: Colors.purple),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutfitDetails() {
    final outfit = widget.outfitRecommendation!;

    return Column(
      children: [
        if (outfit.top != null)
          _buildOutfitItem('Top', outfit.top!, Icons.checkroom),
        if (outfit.bottom != null)
          _buildOutfitItem('Bottom', outfit.bottom!, Icons.straighten),
        if (outfit.shoes != null)
          _buildOutfitItem('Shoes', outfit.shoes!, Icons.hiking),
        if (outfit.accessory != null)
          _buildOutfitItem('Accessory', outfit.accessory!, Icons.star),
      ],
    );
  }

  Widget _buildOutfitItem(String category, String item, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            '$category: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            item.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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
