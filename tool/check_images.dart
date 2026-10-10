import 'dart:convert';
import 'dart:io';

void main() {
  stdout.writeln('========================================================');
  stdout.writeln('  UdyogaSethu - Asset Image Manifest & File Verifier');
  stdout.writeln('========================================================\n');

  final jobsManifestFile = File('assets/images/jobs/manifest.json');
  final commoditiesManifestFile = File('assets/images/commodities/manifest.json');

  int totalExpected = 0;
  int totalFound = 0;
  int totalMissing = 0;
  int totalOversized = 0;

  // 1. Check Job Images Manifest
  stdout.writeln('[1/2] Checking Job Categories and Sub-Type Images...');
  if (!jobsManifestFile.existsSync()) {
    stderr.writeln('ERROR: assets/images/jobs/manifest.json not found!');
  } else {
    try {
      final json = jsonDecode(jobsManifestFile.readAsStringSync()) as Map<String, dynamic>;
      final categories = json['categories'] as List<dynamic>? ?? [];

      for (final cat in categories) {
        final catMap = cat as Map<String, dynamic>;
        final slug = catMap['slug'] as String? ?? 'unknown';
        final variants = (catMap['variants'] as List<dynamic>?) ?? [];

        for (final v in variants) {
          final path = v.toString();
          totalExpected++;
          final file = File(path);

          if (file.existsSync()) {
            totalFound++;
            final sizeKb = file.lengthSync() / 1024.0;
            if (sizeKb > 70.0) {
              totalOversized++;
              stdout.writeln('  [WARN] $path exists (${sizeKb.toStringAsFixed(1)} KB) - exceeds 70 KB target');
            } else {
              stdout.writeln('  [OK]   $path (${sizeKb.toStringAsFixed(1)} KB)');
            }
          } else {
            totalMissing++;
            stdout.writeln('  [MISS] $path (Category: $slug) -> Gradient fallback active');
          }
        }
      }
    } catch (e) {
      stderr.writeln('Error reading jobs manifest: $e');
    }
  }

  stdout.writeln('');

  // 2. Check Commodity Images Manifest
  stdout.writeln('[2/2] Checking Mandi Commodity & Crop Images...');
  if (!commoditiesManifestFile.existsSync()) {
    stderr.writeln('ERROR: assets/images/commodities/manifest.json not found!');
  } else {
    try {
      final json = jsonDecode(commoditiesManifestFile.readAsStringSync()) as Map<String, dynamic>;
      final commodities = json['commodities'] as List<dynamic>? ?? [];

      for (final comm in commodities) {
        final cMap = comm as Map<String, dynamic>;
        final slug = cMap['slug'] as String? ?? 'unknown';
        final path = cMap['assetPath']?.toString() ?? 'assets/images/commodities/$slug.webp';
        totalExpected++;
        final file = File(path);

        if (file.existsSync()) {
          totalFound++;
          final sizeKb = file.lengthSync() / 1024.0;
          if (sizeKb > 50.0) {
            totalOversized++;
            stdout.writeln('  [WARN] $path exists (${sizeKb.toStringAsFixed(1)} KB) - exceeds 50 KB target');
          } else {
            stdout.writeln('  [OK]   $path (${sizeKb.toStringAsFixed(1)} KB)');
          }
        } else {
          totalMissing++;
          stdout.writeln('  [MISS] $path ($slug) -> Initial & gradient fallback active');
        }
      }
    } catch (e) {
      stderr.writeln('Error reading commodities manifest: $e');
    }
  }

  stdout.writeln('\n--------------------------------------------------------');
  stdout.writeln('Summary:');
  stdout.writeln('  Total Defined in Manifests: $totalExpected');
  stdout.writeln('  Existing on Disk:           $totalFound');
  stdout.writeln('  Missing (using Fallback):   $totalMissing');
  stdout.writeln('  Oversized Assets:           $totalOversized');
  stdout.writeln('--------------------------------------------------------');

  if (totalMissing > 0) {
    stdout.writeln('\n[NOTE] Missing image files have polished gradient + letter fallbacks active.');
    stdout.writeln('Refer to docs/IMAGE_PROMPTS.md to generate WebP assets and place them in the target folders.');
  } else {
    stdout.writeln('\n[SUCCESS] All manifest assets exist on disk.');
  }
}
