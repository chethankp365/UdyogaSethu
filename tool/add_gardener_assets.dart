// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final jpg1Path = r'C:\Users\cheth\.gemini\antigravity-ide\brain\bfbc3b7b-7703-41e1-a003-a44d713f8b91\gardener_one_1791644080821.jpg';
  final jpg2Path = r'C:\Users\cheth\.gemini\antigravity-ide\brain\bfbc3b7b-7703-41e1-a003-a44d713f8b91\gardener_two_1791644100524.jpg';

  final file1 = File(jpg1Path);
  final file2 = File(jpg2Path);

  if (!file1.existsSync() || !file2.existsSync()) {
    print('Error: Source gardener jpg files not found!');
    return;
  }

  final img1 = img.decodeImage(file1.readAsBytesSync())!;
  final resized1 = img.copyResize(img1, width: 800, height: 450);
  final webp1 = img.encodeWebP(resized1, quality: 80);
  File('assets/images/jobs/gardener-1.webp').writeAsBytesSync(webp1);
  print('Saved assets/images/jobs/gardener-1.webp (${(webp1.length / 1024).toStringAsFixed(1)} KB)');

  final img2 = img.decodeImage(file2.readAsBytesSync())!;
  final resized2 = img.copyResize(img2, width: 800, height: 450);
  final webp2 = img.encodeWebP(resized2, quality: 80);
  File('assets/images/jobs/gardener-2.webp').writeAsBytesSync(webp2);
  print('Saved assets/images/jobs/gardener-2.webp (${(webp2.length / 1024).toStringAsFixed(1)} KB)');

  // Update jobs manifest.json
  final manifestFile = File('assets/images/jobs/manifest.json');
  final data = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final categories = data['categories'] as List<dynamic>;

  final exists = categories.any((c) => (c as Map<String, dynamic>)['slug'] == 'gardener');
  if (!exists) {
    categories.add({
      'slug': 'gardener',
      'name': 'Gardening & Landscaping',
      'icon': 'yard',
      'variants': [
        'assets/images/jobs/gardener-1.webp',
        'assets/images/jobs/gardener-2.webp'
      ],
      'keywords': [
        'gardener',
        'gardening',
        'landscaping',
        'plants',
        'lawn',
        'mowing',
        'nursery',
        'horticulture',
        'tree pruning',
        'watering'
      ]
    });

    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    print('Updated assets/images/jobs/manifest.json with gardener category (Total: ${categories.length} categories)');
  }
}
