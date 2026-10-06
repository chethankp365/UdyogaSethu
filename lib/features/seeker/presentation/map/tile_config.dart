import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration for OpenStreetMap or production tile provider (e.g. Mapbox, MapTiler).
/// Keeping this decoupled allows swapping out tile providers for production deployments.
class TileConfig {
  final String urlTemplate;
  final String userAgentPackageName;
  final String attributionText;
  final int maxZoom;
  final int minZoom;

  const TileConfig({
    this.urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.userAgentPackageName = 'in.udyogasethu',
    this.attributionText = '© OpenStreetMap contributors',
    this.maxZoom = 19,
    this.minZoom = 3,
  });
}

/// Global provider for TileConfig. Can be overridden in production or testing.
final tileConfigProvider = Provider<TileConfig>((ref) {
  return const TileConfig();
});
