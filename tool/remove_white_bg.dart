import 'dart:io';

import 'package:image/image.dart' as img;

/// Removes near-white background from a PNG by converting near-white pixels to
/// transparent (with a soft edge to preserve anti-aliased borders).
///
/// Usage:
///   dart run tool/remove_white_bg.dart
///
/// Default input:
///   assets/skoolwala_logo.png
void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args.first : 'assets/skoolwala_logo.png';
  final inputFile = File(inputPath);

  if (!inputFile.existsSync()) {
    stderr.writeln('Input not found: $inputPath');
    exitCode = 2;
    return;
  }

  final bytes = inputFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode image (is it a valid PNG?): $inputPath');
    exitCode = 3;
    return;
  }

  // Tunable thresholds.
  // - Pixels with min(R,G,B) >= high become fully transparent.
  // - Pixels with min(R,G,B) between low..high are faded out proportionally.
  const int low = 230;
  const int high = 252;

  // Only treat as “background white” if the pixel is bright AND not strongly tinted.
  const int maxChannelMin = 235;
  const int tintTolerance = 28; // how much one channel can differ from others

  int changed = 0;

  for (int y = 0; y < decoded.height; y++) {
    for (int x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);
      final a = pixel.a.toInt();
      if (a == 0) continue;

      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);

      // Skip removal for pixels that are bright but clearly tinted.
      final int rg = (r - g).abs();
      final int rb = (r - b).abs();
      final int gb = (g - b).abs();
      final bool isTinted =
          rg > tintTolerance || rb > tintTolerance || gb > tintTolerance;

      final bool isBrightEnough = maxC >= maxChannelMin;
      if (!isBrightEnough || isTinted) continue;

      if (minC >= high) {
        decoded.setPixelRgba(x, y, r, g, b, 0);
        changed++;
        continue;
      }

      if (minC >= low) {
        final t = (high - minC) / (high - low); // 1..0
        final newA = (a * t).round().clamp(0, 255);
        if (newA != a) {
          decoded.setPixelRgba(x, y, r, g, b, newA);
          changed++;
        }
      }
    }
  }

  // Backup original once.
  final backupPath = '$inputPath.bak';
  final backupFile = File(backupPath);
  if (!backupFile.existsSync()) {
    backupFile.writeAsBytesSync(bytes);
  }

  final encoded = img.encodePng(decoded, level: 6);
  inputFile.writeAsBytesSync(encoded);

  stdout.writeln('Processed: $inputPath');
  stdout.writeln('Backup: $backupPath');
  stdout.writeln('Pixels adjusted: $changed');
}
