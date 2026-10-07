// ignore_for_file: avoid_print
// tool/build_job_assets.dart
// Generates and manages the 18 categories x 2 variants = 36 WebP job images
// in assets/images/jobs/{category-slug}-{1|2}.webp (800x450, under 70 KB each).
import 'dart:io';
import 'package:image/image.dart' as img;

const Map<String, List<int>> categoryColorThemes = {
  'loader': [0xFFE65100, 0xFFFFB74D], // Amber / Orange
  'agri_labour': [0xFF2E7D32, 0xFF81C784], // Earth Green
  'domestic_help': [0xFF00838F, 0xFF4DD0E1], // Teal / Cyan
  'driver': [0xFF1565C0, 0xFF64B5F6], // Blue
  'cleaner': [0xFF00695C, 0xFF4DB6AC], // Mint Teal
  'mason': [0xFF4E342E, 0xFFA1887F], // Terracotta / Stone
  'carpenter': [0xFF5D4037, 0xFFBCAAA4], // Warm Wood
  'electrician': [0xFFF57F17, 0xFFFFF176], // Yellow Amber
  'delivery': [0xFFC2185B, 0xFFF06292], // Vibrant Rose
  'painting': [0xFF6A1B9A, 0xFFBA68C8], // Purple / Indigo
  'plumbing': [0xFF0277BD, 0xFF4FC3F7], // Sky Blue
  'construction': [0xFF37474F, 0xFF90A4AE], // Steel / Slate
  'content-writing': [0xFF283593, 0xFF7986CB], // Indigo / Navy
  'design-data-work': [0xFF4527A0, 0xFF9575CD], // Deep Purple
  'tutoring-academics': [0xFF1565C0, 0xFF42A5F5], // Academic Blue
  'campus-brand-promotion': [0xFFAD1457, 0xFFFF4081], // Pink / Coral
  'retail-food-service': [0xFFD84315, 0xFFFF8A65], // Warm Terracotta / Coffee
  'delivery-gig-work': [0xFF00695C, 0xFF26A69A], // Emerald Gig
};

void main() async {
  final jobsDir = Directory('assets/images/jobs');
  if (!jobsDir.existsSync()) {
    jobsDir.createSync(recursive: true);
  }

  print('Building category WebP images in ${jobsDir.path}...');

  for (final entry in categoryColorThemes.entries) {
    final slug = entry.key;
    final colors = entry.value;

    for (int variant = 1; variant <= 2; variant++) {
      final fileName = '$slug-$variant.webp';
      final file = File('${jobsDir.path}/$fileName');

      // Create high-res 800x450 canvas
      final image = img.Image(width: 800, height: 450);

      final c1 = colors[0];
      final c2 = colors[1];

      // Draw smooth diagonal gradient
      for (int y = 0; y < 450; y++) {
        for (int x = 0; x < 800; x++) {
          final t = (x / 800.0 * 0.7 + y / 450.0 * 0.3).clamp(0.0, 1.0);
          final r = (((c1 >> 16) & 0xFF) * (1 - t) + ((c2 >> 16) & 0xFF) * t).round();
          final g = (((c1 >> 8) & 0xFF) * (1 - t) + ((c2 >> 8) & 0xFF) * t).round();
          final b = ((c1 & 0xFF) * (1 - t) + (c2 & 0xFF) * t).round();

          // Add subtle texture pattern
          final noise = ((x * 17 + y * 31) % 7) - 3;
          final finalR = (r + noise).clamp(0, 255);
          final finalG = (g + noise).clamp(0, 255);
          final finalB = (b + noise).clamp(0, 255);

          image.setPixelRgba(x, y, finalR, finalG, finalB, 255);
        }
      }

      // Draw decorative soft rounded card / frame in center
      final cardLeft = variant == 1 ? 60 : 80;
      final cardTop = 50;
      final cardRight = variant == 1 ? 740 : 720;
      final cardBottom = 400;

      for (int cy = cardTop; cy < cardBottom; cy++) {
        for (int cx = cardLeft; cx < cardRight; cx++) {
          final pixel = image.getPixel(cx, cy);
          // Lighten card interior slightly
          final cr = (pixel.r * 0.85 + 255 * 0.15).round().clamp(0, 255);
          final cg = (pixel.g * 0.85 + 255 * 0.15).round().clamp(0, 255);
          final cb = (pixel.b * 0.85 + 255 * 0.15).round().clamp(0, 255);
          image.setPixelRgba(cx, cy, cr, cg, cb, 255);
        }
      }

      // Encode as clean WebP
      final webpBytes = img.encodeWebP(image, quality: 75);
      file.writeAsBytesSync(webpBytes);
      print('Saved $fileName (${(webpBytes.length / 1024).toStringAsFixed(1)} KB)');
    }
  }

  print('Done! Generated 36 category WebP images.');
}
